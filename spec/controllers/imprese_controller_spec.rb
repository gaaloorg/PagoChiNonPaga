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

RSpec.describe ImpreseController, type: :controller do
  before{ Impresa.skip_callback(:validation, :before, :assegna_coordinate)}

  it "should not create impresa" do
    get :new
    expect(response).to redirect_to new_utente_session_path
  end

  it "should not let a cliente to create an impresa" , :skip_before do
    citta= Citta.create(nome: "Palermo", provincia: "Pa", regione: "Sicilia",polo_id: 1)
    cliente = createCliente("Bianco","Bianco",citta)
    Utente.where(actable_id: cliente.id).first.confirm
    sign_in cliente
    get :new
    expect(response).to redirect_to root_path
  end

  it "should let create an impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    sign_in titolare
    get :new
    expect(response).to render_template :new
  end

  it "should let edit an impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm

    verificata= true
    congelata=false
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    sign_in titolare
    get :edit, id: impresa.id ,nome: impresa.nome
    expect(response).to render_template :edit
  end
  it "should let destroy an impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm

    verificata= true
    congelata=false
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    sign_in titolare
    put :destroy , id: impresa.id ,nome: impresa.nome
    expect(response).to redirect_to imprese_path
  end

  it "should not let a titolare edit anoter titolare impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    titolare2 = createTitolare("Mario","Bianchi",citta)
    Utente.where(actable_id: titolare2.id).first.confirm
    verificata= true
    congelata=false
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    sign_in titolare2
    get :edit , id: impresa.id ,nome: impresa.nome
  end

  it "should check url if modified" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    verificata= true
    congelata=false
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    get :show, nome: "errato", id: impresa.id
    expect(response).to redirect_to impresa_path(nome: impresa.nome, id: impresa.id)
  end

  it "should not edit impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    verificata= true
    congelata=true
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    sign_in titolare
    get :edit , nome: impresa.nome, id: impresa.id
    expect(response).to_not render_template :edit
  end


  it "should not edit impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    verificata= false
    congelata=true
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    sign_in titolare
    get :edit , nome: impresa.nome, id: impresa.id
    expect(response).to_not render_template :edit
  end

  it "should not edit impresa" do
    citta= Citta.create(nome: "Roma", provincia: "Rm", regione: "Lazio",polo_id: 1)
    titolare = createTitolare("Mario","Rossi",citta)
    Utente.where(actable_id: titolare.id).first.confirm
    verificata= false
    congelata=false
    impresa =createImpresa("impresa","imp@resa.com",citta,titolare,congelata,verificata)
    get :edit , nome: impresa.nome, id: impresa.id
    expect(response).to_not render_template :edit
  end
end
