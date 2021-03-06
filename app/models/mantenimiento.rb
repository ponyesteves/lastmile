class Mantenimiento < ActiveRecord::Base
  include Importador, Comun

  def self.resumen reporte, args = {}
    precio_gasoil = args[:precio_gasoil]
    filtrado = self.where(reporte: reporte)
    hsh = {}
    horas filtrado, hsh
    gasoil filtrado, hsh, precio_gasoil
    gastos_varios filtrado, hsh
    hsh
  end
  def self.detalle reporte, args = {}
    super reporte, [:fecha, :doc, :horometro, :obs], [['nombre', :insumo], :cantidad, :costoestandar], args
  end
  private

    def self.horas filtrado, hsh
      maquinas = filtrado.select(:maquina).distinct.map {|i| hsh[i.maquina] = {} }
      max = filtrado.where("insumo ilike 'gasoil%'").group(:maquina).maximum(:horometro)
      min = filtrado.where("insumo ilike 'gasoil%'").group(:maquina).minimum(:horometro)
      hsh.each do |k,v|
        min[k] ||= 0
        max[k] ||= 0
        hsh[k] = {horas: (max[k] - min[k]).to_i}
      end
    end

    def self.gasoil filtrado, hsh, precio
      filtrado.where("insumo ilike 'gasoil%'").group(:maquina).sum(:cantidad).each do |k,v|
        hsh[k].merge!({gasoil_cantidad: v.to_i, gasoil_costo: (v * precio).to_f })
      end
    end

    def self.gastos_varios filtrado, hsh
      filtrado.where("insumo not ilike 'gasoil%'").group(:maquina).sum("cantidad * costoestandar").each do |k,v|
        hsh[k].merge!({gastos_varios: v.to_i})
      end
    end
end

Mantenimiento::SINONIMOS = {
  'descripción': 'obs',
  'documento': 'doc'
}
