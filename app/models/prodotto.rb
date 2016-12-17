class Prodotto < ActiveRecord::Base
  belongs_to :impresa
  has_and_belongs_to_many :ordini

  # Validations necessarie per la registrazione
  validates :nome, :prezzo, :qta, :descrizione, :impresa_id, presence: true
  #TODO: servono controlli sui duplicati?

  # Ritorna il nome del prodotto
  def getNome
    self.nome
  end

  # Necessario per mostrare il nome dell'Entita in RailsAdmin
  def name
    getNome
  end

end
