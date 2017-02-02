class OrdiniController < ApplicationController
  require 'paypal-sdk-rest'
  include PayPal::SDK::REST
  include PayPal::SDK::Core::Logging
  before_action :set_ordine, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_utente!
  before_filter :is_mio_ordine?, only: [:show,:destroy]
  before_filter :is_titolare?, only: :edit
  before_filter :is_in_attesa?, only: :destroy
  before_action :restore_quantita, only: :destroy

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

  # GET /ordini/1
  # GET /ordini/1.json
  def show
  end



  # GET /ordini/1/edit
  def edit
  end

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
          @ordine= Ordine.create(cliente_id: current_utente.actable_id, stato_ordine_id: 1,impresa_id: impresa ,prodotti: prodotti,totale: 0.0)
          @ordine.setTotale
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

  # PATCH/PUT /ordini/1
  # PATCH/PUT /ordini/1.json
  def update
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

  # DELETE /ordini/1
  # DELETE /ordini/1.json
  def destroy

    @ordine.destroy
    respond_to do |format|
      format.html { redirect_to ordini_url, notice: 'Ordine was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def paypal_url
    @ordine = Ordine.find(params[:id])
    @payment = Payment.new({
      :intent =>  "sale",

      :payer =>  {
        :payment_method =>  "paypal" },

      :redirect_urls => {
        :return_url => "http://localhost:3000/mieiOrdini/#{@ordine.id}/checkout",
        :cancel_url => "http://localhost:3000/" },

      :transactions =>  [{
        :payee => {
          :email => @ordine.impresa.titolare.email_paypal
        },
        :item_list => {
          #Items vuota, viene riempita in ciclo sottostante
          :items => []},
        :amount =>  {
          :total =>  @ordine.totale,
          :currency =>  "EUR" },
        :description =>  "This is the payment transaction description." }]})

        unique_ids= @ordine.prodotti.uniq
        unique_ids.each do |prodotto|
          @payment.transactions.at(0).item_list.items.merge!({
            :name => prodotto.nome,
            :price => prodotto.prezzo,
            :currency => "EUR",
            :quantity => @ordine.occorrenzeProdotto(prodotto.id)
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

  def checkout

    payment = Payment.find(params[:paymentId])
    if payment.execute( :payer_id => params[:PayerID] )

      @pagato = StatoOrdine.find_by_stato(StatoOrdine.PAGATO)
      @ordine = Ordine.find(params[:id])
      @ordine.update_attribute('stato_ordine',@pagato)
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
prende in ingresso il carrello e l'id di una impresa, cerca tutti i prodotti del carrello che appartengono a quella impresa
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

  def is_in_attesa?
    if (@ordine.getStato == StatoOrdine.ATTESA)
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def ordine_params
      params.require(:ordine).permit(:data, :cliente_id, :impresa_id, :stato_ordine_id)
    end
end
