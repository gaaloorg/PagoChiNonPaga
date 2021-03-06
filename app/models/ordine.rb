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

class Ordine < ActiveRecord::Base
  belongs_to :cliente
  belongs_to :impresa
  has_and_belongs_to_many :prodotti
  belongs_to :stato_ordine

  # Validations necessarie per la registrazione
  validates :cliente_id, :impresa_id, :stato_ordine_id, presence: true
  validate :has_prodotti #custom validation
  validates_numericality_of :totale, :greater_than_or_equal_to => 0
  validates_numericality_of :spedizione, :greater_than_or_equal_to => 0


#validate sul totale disabilitato altrimenti non crea l'ordine. TODO metodo per il calcolo del totale

  # Una relazione habtm ha bisogno di una custom validation
  def has_prodotti
    errors.add(:base, 'Un ordine deve contenere almeno un prodotto.') if self.prodotti.blank?
    #se non ci sono prodotti viene generato un errore
  end

  # Ritorna lo stato dell'ordine in forma di stringa
  def getStato
    stato_ordine.stato
  end

  def occorrenzeProdotto(prodotto)
    self.prodotti.where(id: prodotto).count
  end

  def setTotale
    ids = self.prodotti.ids.uniq
    totale = 0.0
    ids.each do |id_prodotto|
      prezzo = Prodotto.find(id_prodotto).prezzo
      totale += occorrenzeProdotto(id_prodotto)*prezzo
    end
    new_totale= self.totale + totale
    self.update_attribute('totale', new_totale)
  end

  def setSpedizione(sped)
    if(sped>=0)
      @cliente= Cliente.find(self.cliente.id)
      self.update_attribute('spedizione',sped)
      @conferma = StatoOrdine.find_by_stato(StatoOrdine.CONFERMA)
      self.update_attribute('stato_ordine_id',@conferma.id) #lo stato va in conferma, in attesa della decisione del cliente
      #CustomMailer.modifica_stato_ordine(@cliente,self).deliver_now
    else
      errors.add(:spedizione, "La spedizione deve essere >= 0€")
    end
  end

  def getSpedizione
    self.spedizione
  end

  def getTotale
    self.totale + self.getSpedizione
  end

  # Necessario per mostrare il nome dell'Entita in RailsAdmin
  def name
    "#Ordine: #{self.id} del Cliente: #{self.cliente_id}"
  end

  def getStatiDisponibili
    stati =[ self.stato_ordine]
    if self.stato_ordine.stato == StatoOrdine.PAGATO
      stati << StatoOrdine.find(4)
    end
    stati
  end

  def spedizione?
    self.stato_ordine.stato == StatoOrdine.PAGATO
  end
end
