json.extract! impresa, :id, :nome, :telefono, :fax, :giorni_orari, :email, :sitoweb, :facebook, :descrizione, :lat, :lng, :verificato, :congelato, :created_at, :updated_at
json.url impresa_url(impresa, format: :json)