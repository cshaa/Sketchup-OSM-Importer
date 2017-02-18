# (C) 2015 by Aqualung (Jim Hamilton)
# (C) 2017 by m93a (Michal Grňo)
# Permission granted to freely use this code as long as this statement
# and the list of authors are included in any derivative work(s).
#
# m93a_osm_importer.rb
#
# Import OSM-type 2D ways
#
# version 1.1 - February 18, 2017 - Uses Sketchup's internal geo coordinates
#----------------------------------------------------------------------------------------
require 'sketchup.rb'
require 'rexml/document'
include REXML
#----------------------------------------------------------------------------------------
module M93A
  module OSM_Importer

    def m93a_osm_import()

      model = Sketchup.active_model
      imported = model.entities.add_group

      # Check for georeferencing
      unless model.georeferenced?
        UI.messagebox("The model needs to be georeferenced!")
        return
      end

      # Start the operation
      model.start_operation("Import OSM File",true)

      # Ask user for the OSM file
      base = UI.openpanel("Select OSM File", "~", "OSM Files|*.osm;||")
      path = File.dirname(base) + '/' + File.basename(base,".*") + '.osm'

      # Parse the file
      doc = Document.new File.new path
      nodes = Hash.new

      # Read positions of nodes
      doc.elements.each("osm/node") { |n|
        id = n.attributes["id"]
        lat = n.attributes["lat"].to_f
        lon = n.attributes["lon"].to_f
        nodes[id] = model.latlong_to_point [lat,lon]
      }

      # Add ways to the model
      doc.elements.each("osm/way") { |w|
        points = []
        group = imported.entities.add_group
        w.elements.each("nd") { |n|
          points.push nodes[n.attributes["ref"]]
        }
        group.entities.add_edges points
      }

      # Commit the operation
      model.commit_operation
    end


    unless file_loaded?("m93a_osm_importer.rb")
      UI.menu("PlugIns").add_item("Import OSM File (new)") { m93a_osm_import() }
      file_loaded("m93a_osm_importer.rb")
    end

  end #OSM_Importer
end #M93A
