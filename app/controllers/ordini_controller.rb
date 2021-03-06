=begin
Copyright 2017 Alessandro Profiti, Gabriele Restuccia, Lorenzo Ricelli.

This file is part of PagoChiNonPaga.

PagoChiNonPaga is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PagoChiNonPaga is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
=end

class OrdiniController < ApplicationController
  require 'paypal-sdk-rest'
  include PayPal::SDK::REST
  include PayPal::SDK::Core::Logging
  before_action :set_ordine, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_utente!
  before_filter :is_mio_ordine?, only: [:show,:destroy]
  before_filter :is_titolare?, only: :edit
  before_filter :is_eliminabile?, only: :destroy
  before_action :restore_quantita, only: :destroy
  before_action :is_in_conferma?, only: :paypal_url
  before_filter :titolare_paypal?, only: [:create,:show]
  # GET /ordini
  # GET /ordini.json
  def index
    id = current_utente.actable_id
    if current_utente.isCliente?
      @ordini = Cliente.find(id).ordini
      @ordiniAttivi = Cliente.find(id).getOrdiniAttivi
      @ordiniCompletati = @ordini - @ordiniAttivi
    elsif current_utente.isTitolare?
      @ordini = []
      @ordiniAttivi = []
      Titolare.find(id).imprese.each do |impresa|
        @ordiniAttivi += impresa.getOrdiniAttivi
        @ordini += impresa.ordini
      end
      @ordiniCompletati = @ordini - @ordiniAttivi
    end
  end

  # GET /mieiOrdini/:id
  # GET /mieiOrdini/:id.json
  def show
    case @ordine.stato_ordine.stato
    when StatoOrdine.ATTESA
      # Il titolare puo' modificare i dati per inserire costo di spedizione
      flash[:alert] = "In attesa che il titolare inserisca le spese di Spedizione"
    when StatoOrdine.CONFERMA
      # In attesa che il clienti accetti i costi di spedizione e paghi l'ordine
      flash[:notice] = "In attesa di conferma da parte dell'utente"
    when StatoOrdine.PAGATO
      # In attesa che il Titolare contrassegni l'ordine come spedito
      # Non puo' essere modificato dal Titolare
      flash[:notice] = "Ordine pagato. In attesa di spedizione da parte del titolare"
    when StatoOrdine.SPEDITO
      # In attesa di conferma ricezione da parte del cliente
      # Non puo' essere modificato dal Titolare
      flash[:notice] = "Ordine in attesa che il cliente confermi il ricevimento dell'ordine"
    when StatoOrdine.RICEVUTO
      # L'ordine e' completato e non puo' essere modificato
      flash[:success] = "Ordine completato"
    else
    end
  end

  # GET /mieiOrdini/:id/edit
  def edit
    # Si puo' modificare solamente se e' in ATTESA oppure in PAGATO
    stato = @ordine.stato_ordine.stato
    if (stato == StatoOrdine.CONFERMA) ||
       (stato == StatoOrdine.SPEDITO) ||
       (stato == StatoOrdine.RICEVUTO)
       # Reindirizzo poiche' e' un ordine non modificabile
       redirect_to ordine_path(@ordine)
    end
  end
  # POST /mieiOrdini/:id/prepara_ordini
  def prepara_ordini

    #SETUP VARIABILI
    ordine_riuscito= true
    carrello= current_utente.getCarrello              #carrello utente attuale
    imprese = carrello.impreseCarrello                #imprese implicate in carrello
    impresa_prodotti= carrello.impresaElemento        #array di tuple (impresa, carrello_prodotti)
    #SETUP VARIABILI

    if check_imprese(imprese)
      #A QUESTO PUNTO TUTTE LE IMPRESE SONO O VERIFICATE E NON CONGELATE
      imprese.each do |impresa|
        prodotti= setOrdine(impresa_prodotti,impresa)
        if prodotti == nil
          ordine_riuscito= false
        else
          @ordine= Ordine.create(cliente_id: current_utente.actable_id, stato_ordine_id: 1,impresa_id: impresa ,prodotti: prodotti,totale: 0.0,spedizione: 0.0)
          @ordine.setTotale
=begin
          decommentare per invio email ordine creato
          @titolare = Titolare.find(@ordine.impresa.titolare.id)
          CustomMailer.ordine_creato(@titolare,@ordine).deliver_now
=end
        end
      end
    else
      return redirect_to carrello_path(id: carrello.id)
    end
    if ordine_riuscito
      carrello.destroy
      flash[:notice] = "Il titolare dell'impresa calcolerà e ti comunicherà le spese di spedizione. Attendi che lo stato diventi in attesa di conferma"
      redirect_to ordini_path
    else
      flash[:error] = "Errore con la disponibilità dei prodotti. Controlla e leva quelli terminati"
      redirect_to carrello_path(id: carrello.id)
    end
  end

  # POST  /mieiOrdini
  def create
    @ordine = Ordine.new(ordine_params)

    respond_to do |format|
      if @ordine.save
        format.html { redirect_to @ordine, notice: 'Ordine was successfully created.' }
        format.json { render :show, status: :created, location: @ordine }
      else
        format.html { render :new }
        format.json { render json: @ordine.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT  /mieiOrdini/:id
  # PATCH/PUT /mieiOrdini/:id.json
  def update
    if @ordine.stato_ordine.stato == StatoOrdine.ATTESA
      @ordine.setSpedizione(params[:ordine][:spedizione].to_i)
    elsif @ordine.stato_ordine.stato == StatoOrdine.PAGATO
      @ordine.update_attribute('stato_ordine',StatoOrdine.find_by_stato(params[:ordine][:stato]))
    end
    respond_to do |format|
      if @ordine.update(ordine_params)
        format.html { redirect_to @ordine, notice: 'Ordine was successfully updated.' }
        format.json { render :show, status: :ok, location: @ordine }
      else
        format.html { render :edit }
        format.json { render json: @ordine.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mieiOrdini/:id
  # DELETE /mieiOrdini/:id.json
  def destroy

=begin
    decommentare per inviare email a destroy ordine
    @titolare = Titolare.find(@ordine.impresa.titolare.id)
    @cliente = Cliente.find(@ordine.cliente.id)
=end
    @ordine.destroy
    respond_to do |format|
      #CustomMailer.ordine_annullato(@titolare,@cliente,@ordine).deliver_now

      format.html { redirect_to ordini_url, notice: 'Ordine was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  #POST /mieiOrdini/:id/paypal_url
  #Esegue transazione paypal
  def paypal_url
    @ordine = Ordine.find(params[:id])
    @payment = Payment.new({
      :intent =>  "sale",

      :payer =>  {
        :payment_method =>  "paypal" },

      :redirect_urls => {
        :return_url => "#{root_url}mieiOrdini/#{@ordine.id}/checkout",
        :cancel_url => root_url },

      :transactions =>  [{
        :payee => {
          :email => @ordine.impresa.titolare.email_paypal
        },
        :item_list => {
          #Items vuota, viene riempita in ciclo sottostante
          :items => []},
        :amount =>  {
          :total =>  @ordine.getTotale,
          :currency =>  "EUR" ,
          :details => {
            :shipping => @ordine.spedizione,
            :subtotal => @ordine.totale
          }
        },
        :description =>  "Transazione ordine #{@ordine.id}, impresa #{@ordine.impresa.getNome}" }]})

        unique_ids= @ordine.prodotti.uniq
        unique_ids.each do |prodotto|
          @payment.transactions.at(0).item_list.items.merge!({
            :name => prodotto.nome,
            :price => prodotto.prezzo,
            :currency => "EUR",
            :quantity => @ordine.occorrenzeProdotto(prodotto.id),
            })
        end
    if @payment.create
      # Redirect the user to given approval url
      @redirect_url = @payment.links.find{|v| v.rel == "approval_url" }.href
      logger.info "Payment[#{@payment.id}]"
      logger.info "Redirect: #{@redirect_url}"

      redirect_to @redirect_url
    else
      logger.error @payment.error.inspect
    end
  end
  #GET /mieiOrdini/:id/checkout
  #Dopo il pagamento effettuato viene eseguita una get a questa risorsa per completare il pagamento
  def checkout
    payment = Payment.find(params[:paymentId])
    if payment.execute( :payer_id => params[:PayerID] )

      @pagato = StatoOrdine.find_by_stato(StatoOrdine.PAGATO)
      @ordine = Ordine.find(params[:id])
      @ordine.update_attribute('stato_ordine',@pagato)
=begin
      Decommentare per mandare mail a titolare e cliente dopo ordine pagato
      @cliente= Cliente.find(@ordine.cliente)
      @titolare= Titolare.find(@ordine.impresa.titolare)
      CustomMailer.pagamento_riuscito_cliente(@cliente).deliver_now
      CustomMailer.pagamento_riuscito_titolare(@titolare).deliver_now
=end
      flash[:notice]= "Pagamento effettuato correttamente"
      redirect_to cliente_path(id: current_utente.actable_id)
    else
      payment.error # Error Hash
      flash[:error]= "Pagamento Non effettuato correttamente"
      redirect_to cliente_path(id: current_utente.actable_id)
    end

  end
  private
=begin
Prende in ingresso il carrello e l'id di una impresa, cerca tutti i prodotti del carrello che appartengono a quella impresa
e li mette in un array di prodotti, ripetendo eventualmente "quantita-volte" l'aggiunta di ogni oggetto

{impresa_id,elemento_carrello}
=end

  def setOrdine(impresa_prodotto,impresa)                         #ingresso => tupla (impresa_id,carrello_prodotti). impresa_id
    prodotti= []
    impresa_prodotto.each do |elemento|
      if elemento.at(0) == impresa
        prodotto= Prodotto.find(elemento.at(1).item_id)
        qta= elemento.at(1).quantity.to_i
        if prodotto.checkDisponibilitaOrdine(qta)
          qta.times do
            prodotti.push(prodotto)
          end
          prodotto.setQuantita(qta)    # SCALA QUANTITÀ DA DB. È un metodo del model di prodotto
        else
          return nil
        end
      end
    end
    prodotti
  end

  def is_mio_ordine?
    if(current_utente.isCliente? && @ordine.cliente_id == current_utente.actable_id)
    elsif (current_utente.isTitolare? && current_utente.isMyImpresa?(Impresa.find(@ordine.impresa_id)))
    else redirect_back
    end
  end

  #controlla che nessuna delle imprese sia congelata
  def check_imprese(imprese)
    imprese.each do |impresa|
      impresa_corrente= Impresa.find(impresa)
      if !(impresa_corrente.isAttiva?)
        flash[:error] = "L'impresa #{impresa_corrente.nome} è congelata. Rimuovi i suoi prodotti"
        return false
      else
        true
      end
    end
  end

  def is_titolare?
     if (current_utente.isTitolare? && current_utente.isMyImpresa?(Impresa.find(@ordine.impresa_id)))
     else redirect_back
     end
  end
    # Use callbacks to share common setup or constraints between actions.
    def set_ordine
      @ordine = Ordine.find(params[:id])
    end

  def is_eliminabile?
    @ordine = Ordine.find(params[:id])
    if (@ordine.getStato == StatoOrdine.ATTESA || @ordine.getStato == StatoOrdine.CONFERMA)
    else
      flash[:notice] = "Non puoi annullare questo ordine"
      redirect_back
    end
  end

  def restore_quantita
    ids = @ordine.prodotti.ids.uniq
    ids.each do |id|
      qta = @ordine.occorrenzeProdotto(id)
      @prodotto = Prodotto.find(id)
      qta_attuale = @prodotto.getQuantita
      @prodotto.update_attribute('qta',qta + qta_attuale)
    end
  end

  def is_in_conferma?
    @ordine = Ordine.find(params[:id])
    if (@ordine.getStato == StatoOrdine.CONFERMA)
    else
      redirect_back
    end
  end

  def titolare_paypal?
    if !@ordine.impresa.titolare.has_email_paypal
      redirect_to cliente_path(id: current_utente.actable_id)
    end
  end

    def ordine_params
      params.require(:ordine).permit(:data, :cliente_id, :impresa_id, :stato_ordine_id, :spedizione)
    end
end
