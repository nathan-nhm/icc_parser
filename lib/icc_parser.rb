#http://www.color.org/icc-book1.PDF B-245
#https://github.com/LuaDist/lcms/blob/master/include/icc34.h
#http://www.color.org/profileinspector.xalter
#https://www.color.org/icc32.pdf

class IccParser
  
  def self.parse_path( icc_profile )
    self.parse_string IO.binread(icc_profile, File.size(icc_profile))
  end
  
  def self.parse_string( icc_profile )
  
    ret = {}
    ret[:size] =             icc_profile[0..3].unpack('L>').first                        #ok
    ret[:cmm_id] =           icc_profile[4..7].encode('utf-8')                           #ok
    ret[:version] =          icc_profile[8..11].unpack('L>').first.to_s(16)              #ok
    ret[:device_class] =     icc_profile[12..15].encode('utf-8')                         #ok
    ret[:color_space] =      icc_profile[16..19].encode('utf-8')                         #ok
    ret[:pcs] =              icc_profile[20..23].encode('utf-8')                         #ok
    begin
      ret[:date] =             DateTime.new( *icc_profile[24..35].unpack("n*") )         #ok
    end

    ret[:magic] =            icc_profile[36..39].encode('utf-8')                         #ok
    ret[:platform] =         icc_profile[40..43].encode('utf-8')                         #ok
    ret[:flags] =            icc_profile[44..47].unpack('L>').first                      #flags could actually be interpreted
    ret[:manufacturer] =     icc_profile[40..43].encode('utf-8')                         #ok
    ret[:model] =            icc_profile[44..47].unpack('L>').first.to_s(16)             #ok
    ret[:attributes] =       icc_profile[48..55].unpack('Q>').first.to_s(2)              #attributes could actually be interpreted
    ret[:rendering_intent] = icc_profile[56..59].unpack('L>').first                      #0 = perceptual ???
#   ret[:illuminant] =       Hash[[:x, :y, :z].zip icc_profile[60..65].unpack('s>3') ]   #??? what no where is the array coming from
    ret[:creator] =          icc_profile[80..83].encode('utf-8')                         #ok

  
    pos = 127 # End of header
    tagnum = icc_profile[128..131].unpack("C*").inject { |r, n| r << 8 | n }
    pos = 132
    tags = {}
    for i in 1..tagnum
      name = icc_profile[pos..pos+3]
      offset = icc_profile[pos+4..pos+7].unpack("C*").inject { |r, n| r << 8 | n }
      size = icc_profile[pos+8..pos+11].unpack("C*").inject { |r, n| r << 8 | n }
      value = case name
      when "cprt"
        icc_profile[offset+8..offset+size-2].encode('utf-8').strip
      when "desc"
        textsize = icc_profile[offset+10..offset+11].unpack("S>").first
        icc_profile[offset+12..offset+10+textsize].encode('utf-8').strip
      else
        case icc_profile[offset..offset+3]
        when "mft1" #icSigLut8Type 
          {:mft1 => {
            :input_chan => icc_profile[offset+8].unpack('C').first,
            :output_chan => icc_profile[offset+9].unpack('C').first,
            :clut_points => icc_profile[offset+10].unpack('C').first,
            :pad => icc_profile[offset+12].unpack('C').first,
            :e00 => icc_profile[offset+13..offset+14].unpack('s>').first,
            :e01 => icc_profile[offset+15..offset+16].unpack('s>').first,
            :e02 => icc_profile[offset+17..offset+18].unpack('s>').first,
            :e10 => icc_profile[offset+19..offset+20].unpack('s>').first,
            :e11 => icc_profile[offset+21..offset+22].unpack('s>').first,
            :e12 => icc_profile[offset+23..offset+24].unpack('s>').first,
            :e20 => icc_profile[offset+25..offset+26].unpack('s>').first,
            :e21 => icc_profile[offset+27..offset+28].unpack('s>').first,
            :e22 => icc_profile[offset+29..offset+30].unpack('s>').first,
            :data => "#{icc_profile[offset+35..offset+size].unpack('C*').length} points"
            }}
        when "mft2" #icSigLut16Type 
          {:mft2 => {
            :input_chan => icc_profile[offset+8].unpack('C').first,
            :output_chan => icc_profile[offset+9].unpack('C').first,
            :clut_points => icc_profile[offset+10].unpack('C').first,
            :pad => icc_profile[offset+12].unpack('C').first,
            :e00 => icc_profile[offset+13..offset+14].unpack('s>').first,
            :e01 => icc_profile[offset+15..offset+16].unpack('s>').first,
            :e02 => icc_profile[offset+17..offset+18].unpack('s>').first,
            :e10 => icc_profile[offset+19..offset+20].unpack('s>').first,
            :e11 => icc_profile[offset+21..offset+22].unpack('s>').first,
            :e12 => icc_profile[offset+23..offset+24].unpack('s>').first,
            :e20 => icc_profile[offset+25..offset+26].unpack('s>').first,
            :e21 => icc_profile[offset+27..offset+28].unpack('s>').first,
            :e22 => icc_profile[offset+29..offset+30].unpack('s>').first,
            :input_ent => icc_profile[offset+31..offset+32].unpack('S>').first,
            :output_ent => icc_profile[offset+33..offset+34].unpack('S>').first,
            :data => "#{icc_profile[offset+35..offset+size].unpack('S>*').length} points"
            }}
        when "dtim"
          { :dtim => DateTime.new( *icc_profile[offset+8..offset+19].unpack("n*") ) }
        when "desc" 
          textsize = icc_profile[offset+10..offset+11].unpack("S>").first
          {:desc => icc_profile[offset+12..offset+10+textsize].encode('utf-8').strip }
        when "XYZ "
          {:"XYZ "=> icc_profile[offset+8..offset+size].unpack('s>*').each_slice(3).collect{ |a| { x: a[0], y: a[1], z: a[2] } } }
        when "sig "
          {:"sig "=> icc_profile[offset+8..offset+size]}
        when "curv"
          {:"curv"=> {
            :count => icc_profile[offset+8..offset+11].unpack('L>*').first,
            :data => icc_profile[offset+12..offset+size].unpack('n*')
            } }
        when "view"
          {:"view"=> {
            :illuminant =>  Hash[[:x, :y, :z].zip icc_profile[offset+8..offset+13].unpack('s>3') ],
            :surroundt =>   Hash[[:x, :y, :z].zip icc_profile[offset+14..offset+19].unpack('s>3') ],
            :std_iluminant => icc_profile[offset+20..offset+size] #???
            } }
        when "meas"
          {:"meas"=> icc_profile[offset+8..offset+size]} #???
        else
          icc_profile[offset..offset+size]
        end
      end
      tags[name.to_sym] = value
      pos += 12
    end
    
    ret["tags"] = OpenStruct.new(tags)
    return OpenStruct.new(ret)
  end
  
# .unpack('C*') 8 bit array match all
# .unpack('S>*') 16 bit array match all
# .unpack('L>*') 32 bit array match all
# > is big endian
# lowercase means signed (usually)
# http://apidock.com/ruby/String/unpack

  
end
