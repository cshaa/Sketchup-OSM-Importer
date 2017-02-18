# (C) 2015 by Aqualung - Permission granted to freely use this code as long
# as this line and the preceding line are included in any derivative work(s)
#
# jimhami42_osm_importer.rb
#
# Import OSM-type 2D ways
#
# version 1.0 (beta) - December 2, 2015 - Initial release of working version
#----------------------------------------------------------------------------------------
require 'sketchup.rb'
require 'rexml/document'
include REXML
#----------------------------------------------------------------------------------------
module Jimhami42
  module OSMPolygonImporter
# MAIN BODY -----------------------------------------------------------------------------
    class << self
      @@model = Sketchup.active_model
# MAIN PROCEDURE ------------------------------------------------------------------------
      def jimhami42_osm_import()
        jimhami42_osm_import_init()
        @@model.start_operation("Import OSM File",true)
        jimhami42_osm_import_get_input()
        puts "Start Time: " + @@timestamp.to_s
        jimhami42_osm_import_create_polygons()
        puts "Created:    " + @@poly_count.to_s
        @@model.commit_operation
        puts "End Time:   " + Time.now.to_s
      end
# INITIALIZE DATA -----------------------------------------------------------------------
      def jimhami42_osm_import_init()
        @@timestamp = Time.now
        @@scale = 1.0
        @@poly_count = 0
        @@display_bb = "No"
        @@name = @@timestamp.strftime("%Y%m%d%H%M%S")
        @@bbox = []
        @@xnode = Hash.new
        @@ynode = Hash.new
      end
# GET USER INPUT ------------------------------------------------------------------------
      def jimhami42_osm_import_get_input()
        base = UI.openpanel("Select OSM File", "~", "OSM Files|*.osm;||")
#        base = UI.openpanel("Select OSM File", "%HOMEPATH%", "OSM Files|*.osm;||")
        @@basename = File.dirname(base) + '/' + File.basename(base,".*")
        puts @@basename
        puts "Parsing XML File ..."
        jimhami42_osm_import_get_data()
        prompts = ["Name: ","Scale: ","Display BB: "]
        defaults = [@@name,@@scale,"No"]
        list = ["","","No|Yes"]
        input = UI.inputbox prompts, defaults, list, "Enter Import Parameters:"
        @@name = input[0]
        @@scale = input[1].to_f
        @@display_bb = input[2]
        for i in 0...4
          @@bbox[i] *= @@scale
        end
      end
# CREATE POLYGONS -----------------------------------------------------------------------
      def jimhami42_osm_import_create_polygons()
        if(@@display_bb == 'Yes')
          group = @@model.entities.add_group
          group.entities.add_edges(Geom::Point3d.new(0,0,0),Geom::Point3d.new(@@bbox[2] - @@bbox[0],0,0),Geom::Point3d.new(@@bbox[2] - @@bbox[0],@@bbox[3] - @@bbox[1],0),Geom::Point3d.new(0,@@bbox[3] - @@bbox[1],0),Geom::Point3d.new(0,0,0))
        end
        i = 0
        @@xmldoc.elements.each("osm/way") do |w|
          pts = []
          group = @@model.entities.add_group
          w.elements.each("nd") {|n| pts.push(Geom::Point3d.new((@@scale * @@xnode[n.attributes["ref"]]) - @@bbox[0],(@@scale * @@ynode[n.attributes["ref"]]) - @@bbox[1],0))}
          group.entities.add_edges(pts)
          i += 1
          if(@@name == "")
            group.name = i.to_s
          else
            group.name = @@name + '-' + i.to_s
          end
          @@poly_count += 1
        end
      end
# GET SHAPEFILE DATA --------------------------------------------------------------------
      def jimhami42_osm_import_get_data()
        file = @@basename + '.osm'
        xmlfile = File.new(file)
        @@xmldoc = Document.new(xmlfile)
        puts "Version: " + @@xmldoc.elements["osm"].attributes["version"]
        @@xmldoc.elements.each("osm/bounds") do |b|
          @@bbox[0] = b.attributes["minlon"].to_f
          @@bbox[1] = b.attributes["minlat"].to_f 
          @@bbox[2] = b.attributes["maxlon"].to_f 
          @@bbox[3] = b.attributes["maxlat"].to_f 
        end
        @@xmldoc.elements.each("osm/node") {|n| @@xnode[n.attributes["id"]] = n.attributes["lon"].to_f; @@ynode[n.attributes["id"]] = n.attributes["lat"].to_f}
      end
    end
#----------------------------------------------------------------------------------------
    unless file_loaded?("jimhami42_osm_importer.rb")
      menu = UI.menu("PlugIns").add_item("Import OSM File") { jimhami42_osm_import() }
      file_loaded("jimhami42_osm_importer.rb")
    end
#----------------------------------------------------------------------------------------
  end
end
