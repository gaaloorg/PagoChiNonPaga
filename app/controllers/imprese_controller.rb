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

class ImpreseController < ApplicationController
  before_action :set_impresa, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_utente! , except: [:index, :show,:autocomplete]
  before_filter :controllo_titolare_impresa, only: [:edit,:destroy]
  before_filter :is_titolare, only: :new
  before_filter :id_nome_match, only: [:show,:edit]
  before_filter :is_abilitata, only: [:edit,:destroy,:show]

  # GET /imprese
  # GET /imprese.json
  def index
    @imprese = Impresa.where(congelato: false, verificato: true)#Impresa.all  #SOLO IMPRESE NON CONGELATE O VERIFICATE
  end

  # GET /imprese/:nome?id=:id
  # GET /imprese/:nome.json?id=:id
  def show
    @hash = Gmaps4rails.build_markers(@impresa) do |impresa, marker|
      marker.lat impresa.latitude
      marker.lng impresa.longitude
    end
  end

  # GET /imprese/new
  def new
    @impresa = Impresa.new
  end

  # GET /imprese/:nome/edit?id=:id
  def edit
  end
  def autocomplete
    imprese = Impresa.all.map do |impresa|
      if impresa.verificato && !(impresa.congelato)  #in autocomplete ci sonno imprese verificate e NON congelate
        {
          nome: impresa.nome,
          id: impresa.id.to_s,
          citta: impresa.citta.nome
        }
      else  #Se impresa è congelata o non verificata mando un JSON vuoto
        {}
      end
    end
    render json: imprese
  end

  # POST /imprese
  # POST /imprese.json
  def create
    # Salvo il record nel DB
    @impresa = Impresa.new(impresa_params)
    # Assegno al titolare che l'ha creata
    @impresa.titolare_id = current_utente.actable_id
    # Se per indirizzo, ho utilizzato l'autocompletiton, seleziono automaticamente la citta corrispondente
    respond_to do |format|
      if @impresa.save
=begin
        decommentare per inviare email creazione impresa
        @titolare= Titolare.find(@impresa.titolare.id)
        CustomMailer.impresa_creata(@titolare,@impresa).deliver_now
=end
        format.html { redirect_to impresa_path(nome: @impresa.nome,id: @impresa.id), notice: 'Impresa was successfully created.' }
        format.json { render :show, status: :created, location: @impresa }
      else
        format.html { render :new }
        format.json { render json: @impresa.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /imprese/:nome?id=:id
  # PATCH/PUT /imprese/:nome.json?id=:id
  def update
    # Se per indirizzo, ho utilizzato l'autocompletiton, seleziono automaticamente la citta corrispondente
    respond_to do |format|
      if @impresa.update(impresa_params)
        format.html { redirect_to impresa_path(nome: @impresa.nome,id: @impresa.id), notice: 'Impresa was successfully updated.' }
        format.json { render :show, status: :ok, location: @impresa }
      else
        format.html { render :edit }
        format.json { render json: @impresa.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /imprese/:nome?id=:id
  # DELETE /imprese/:nome.json?id=:id
  def destroy
    @impresa.destroy
    respond_to do |format|
      format.html { redirect_to imprese_url, notice: 'Impresa was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def is_abilitata #impresa deve essere verificata e NON congelata
      if !(@impresa.verificato && !(@impresa.congelato))
        flash[:error] = "L'impresa e' stata congelata. {er maggiori informazioni, contattare il polo di appartenenza."
        redirect_back
      end
    end
    def is_titolare
       if !(current_utente.isTitolare?)
         redirect_back
       end
    end
    # Check su cambiamento manuale dell'id nell'url
    def id_nome_match
      impresa= Impresa.find(params[:id].to_i)
      if impresa.nome != params[:nome]
        redirect_to(impresa_path(id: impresa.id,nome: impresa.nome))
      end
    end

    def controllo_titolare_impresa
      if !(current_utente.isMyImpresa?(@impresa))
        redirect_back
      end
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_impresa
      @impresa = Impresa.find(params[:id])
    end

    def impresa_params
      params.require(:impresa).permit(:nome, :telefono, :fax, :giorni_orari, :email, :sitoweb, :facebook, :descrizione, :latitude, :longitude, :verificato, :congelato,:citta_id, :image, :indirizzo,:descrizione_indirizzo,:locality,:route,:administrative_area_level_1,:administrative_area_level_2,:administrative_area_level_3,:neighborhood,:country, :sottocategoria_ids => [])
    end
end
