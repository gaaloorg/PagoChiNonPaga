class Indirizzo < ActiveRecord::Base
  belongs_to :citta
  has_many :clienti
  has_many :titolari

  #TODO: decidere come implementare indirizzo e poi aggiungere le validations

  def stampaIndirizzo()
    indirizzo = self.via.to_s + self.ncivico.to_s
  end

  # Necessario per mostrare il nome dell'Entita in RailsAdmin
  def name
    stampaIndirizzo()
  end

end
