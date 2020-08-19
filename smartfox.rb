require 'bindata'
require 'zlib'
require 'stringio'

module SmartFox2X
    TYPE_BOOL   = 1
    TYPE_BYTE   = 2
    TYPE_SHORT  = 3
    TYPE_INT    = 4
    TYPE_LONG   = 5
    TYPE_FLOAT  = 6
    TYPE_DOUBLE = 7
    TYPE_STRING = 8
    TYPE_INT_ARRAY = 12
    TYPE_ARRAY  = 17
    TYPE_OBJECT = 18

    class SFSString < BinData::Primitive
        endian :big
        hide   :len
        int16 :len, :value => lambda { data.length }
        string :data, :read_length => :len

        def get
            self.data
        end

        def set(v)
            self.data = v
        end
    end

    class Term < BinData::Record; end

    class SFSArray < BinData::Record
        endian :big
        hide   :len
        int16 :len, :value => lambda { data.length }
        array :data, :type => :term, :initial_length => :len

        def convert
            data.map do |item|
                case item.otype
                    when TYPE_OBJECT, TYPE_ARRAY then item.payload.convert
                    when TYPE_BOOL..TYPE_LONG then item.payload.to_i
                    when TYPE_STRING then item.payload.to_s
                    else
                        item.payload
                end
            end
        end
    end

    class SFSIntArray < BinData::Record
      endian :big
      hide :len
      int16 :len, :value => lambda { data.length }
      array :data, :type => :int32, :initial_length => :len
    end

    class SFSKeyValue < BinData::Record
        sfs_string :tag
        term :item

        def self.build(tag, item)
            kv = SFSKeyValue.new
            kv.tag = tag
            kv.item = item
            kv
        end
    end

    class SFSObject < BinData::Record
        endian :big
        hide   :len
        int16 :len, :value => lambda { items.length }
        array :items, :type => :sfs_key_value, :initial_length => :len

        def key?(key)
            not send(:[], key).nil?
        end

        def keys
            items.map { |item| item.tag }
        end

        def [](key)
            return super(key) if self.respond_to?(key)
            items.map { |item| item.item.payload if item.tag == key }.compact.first
        end

        def []=(key, value)
            return super(key, value) if self.respond_to?(key)

            if value.is_a?(String)
                str = SFSString.new
                str.assign(value)
                set(key, Term.build(TYPE_STRING, str))
            elsif value.is_a?(SFSObject)
                set(key, Term.build(TYPE_OBJECT, value))
            elsif value.is_a?(Array)
                array = SFSArray.new
                array.push(value)
                set(key, Term.build(TYPE_ARRAY, array))
            elsif value.is_a?(Term)
                set(key, value)
            elsif value.is_a?(Fixnum) or value.is_a?(Float)
                raise "Fixnum and Float are ambiguous types"
            end
        end

        def convert
            hash = Hash.new
            items.each do |item|
                value = case item.item.otype
                    when TYPE_OBJECT, TYPE_ARRAY then item.item.payload.convert
                    when TYPE_BOOL..TYPE_LONG then item.item.payload.to_i
                    when TYPE_STRING then item.item.payload.to_s
                    else
                        item.item.payload
                    end
                hash[item.tag.to_s] = value
            end
            hash
        end

        def merge(hash)
            hash.each do |key, value|
                send(:[]=, key, value)
            end
        end

        def set(key, value)
            for idx in (0...items.length)
                if items[idx].tag == key
                    items[idx].item = value
                    return
                end
            end
            items.push(SFSKeyValue.build(key, value))
            self.len = items.length
        end
    end

    class Term < BinData::Record
        endian :big
        hide   :otype
        uint8  :otype, :initial_value => TYPE_OBJECT
        choice :payload, :selection => :otype do
            int8        TYPE_BOOL
            int8        TYPE_BYTE
            int16       TYPE_SHORT
            int32       TYPE_INT
            int64       TYPE_LONG
            float       TYPE_FLOAT
            double      TYPE_DOUBLE
            sfs_int_array TYPE_INT_ARRAY
            sfs_string  TYPE_STRING
            sfs_array   TYPE_ARRAY
            sfs_object  TYPE_OBJECT
        end

        def self.build(type, payload)
            term = Term.new
            term.otype = type
            term.payload = payload
            term
        end
    end

    class SFSPacket < BinData::Record
        bit1 :binary, :asserted_value => 1
        bit1 :encrypted, :asserted_value => 0
        bit1 :compressed
        bit1 :blueboxed, :asserted_value => 0
        bit1 :bigsized
        resume_byte_alignment
        choice :len, :selection => :bigsized do
            uint16be 0
            uint32be 1
        end
        string :data, :read_length => :len

        def setData(data)
            self.data = data
            self.len = data.length
        end

        def self.read(io)
            pkt = super(io)
            pkt.data = Zlib::inflate(pkt.data) if pkt.compressed == 1
            Term.read(StringIO.new pkt.data)
        end

        def self.build(p, a = 13, c = 1)
            fail "p is expected to be a SFSObject" if not p.is_a?(SFSObject)
            envelope = SFSPacket.new
            base     = Term.new
            base.payload["a"] = Term.build(TYPE_SHORT, a)
            base.payload["c"] = Term.build(TYPE_BYTE, c)
            base.payload["p"] = p
            envelope.setData(base.to_binary_s)
            envelope
        end
    end

end

