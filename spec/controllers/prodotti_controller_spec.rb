require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe ProdottiController, type: :controller do
  before :each do
    @citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    @titolare = createTitolare("Mario","Rossi",@citta)
    Utente.where(actable_id: @titolare.id).first.confirm

  end

    it "should get new prodotto" do
      congelata=false
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      sign_in @titolare
      get :new, impresa_nome: impresa.nome, id: impresa.id
      expect(response).to render_template :new
    end

    it "should get show prodotto" do
      congelata=false
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      sign_in @titolare
      prodotto = Prodotto.create(nome: "prodotto",qta: 10, prezzo: 10, impresa_id: impresa.id,descrizione: "descrizioneee")
      get :show, impresa_nome: impresa.nome, nome: prodotto.nome, id_p: prodotto.id
      expect(response).to render_template :show
    end

    it "should get prodotto index" do
      congelata=false
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      get :index, impresa_nome: impresa.nome, id: impresa.id
    end

    it "should not edit prodotto" do
      congelata=false
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      prodotto = Prodotto.create(nome: "prodotto",qta: 10, prezzo: 10, impresa_id: impresa.id,descrizione: "descrizioneee")
      get :edit, impresa_nome: impresa.nome, nome: prodotto.nome, id_p: prodotto.id
      expect(response).to_not render_template :edit
    end

    it "should not get prodotti impresa congelata" do
      congelata=true
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      prodotto = Prodotto.create(nome: "prodotto",qta: 10, prezzo: 10, impresa_id: impresa.id,descrizione: "descrizioneee")
      get :index , impresa_nome: impresa.nome, id: impresa.id
      expect(response).to_not render_template :index
    end

    it "should not get prodotto impresa congelata" do
      congelata=true
      verificata=true
      impresa =createImpresa("impresa","imp@resa.com",@citta,@titolare,congelata,verificata)
      prodotto = Prodotto.create(nome: "prodotto",qta: 10, prezzo: 10, impresa_id: impresa.id,descrizione: "descrizioneee")
      get :show , impresa_nome: impresa.nome, nome: prodotto.nome,id_p: prodotto.id
      expect(response).to_not render_template :show
    end

end
