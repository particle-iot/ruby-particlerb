require 'particle/model'

module Particle

  # Domain model for one Particle device
  class Device < Model
    ID_REGEX = /^\h{24}$/
    PRODUCT_IDS = {
      0 => "Core".freeze,
      6 => "Photon".freeze,
      8 => "P1".freeze,
      10 => "Electron".freeze,
      31 => "Raspberry Pi".freeze
    }

    def initialize(client, attributes)
      super(client, attributes)

      if attributes.is_a? String
        if attributes =~ ID_REGEX
          @attributes = { id: attributes }
        else
          @attributes = { name: attributes }
        end
      else
        # Listing all devices returns partial attributes so check if the
        # device was fully loaded or not
        @fully_loaded = true if attributes.key?(:variables)
      end
    end

    def id
      get_attributes unless @attributes[:id]
      @attributes[:id]
    end

    def name
      get_attributes unless @attributes[:name]
      @attributes[:name]
    end

    def id_or_name
      @attributes[:id] || @attributes[:name]
    end

    attribute_reader :connected, :product_id, :last_heard, :last_app,
      :last_ip_address

    alias_method :connected?, :connected

    def functions
      get_attributes unless @fully_loaded
      @attributes[:functions]
    end

    def variables
      get_attributes unless @fully_loaded
      @attributes[:variables]
    end

    def product
      PRODUCT_IDS[product_id]
    end

    def get_attributes
      @loaded = @fully_loaded = true
      @attributes = @client.device_attributes(self)
    end

    # Add a Particle device to your account
    #
    # @example Add a Photon by its id
    #   Particle.device('f8bbe1e6e69e05c9c405ba1ca504d438061f1b0d').claim
    def claim
      new_device = @client.claim_device(self)
      self
    end

    # Remove a Particle device from your account
    #
    # @example Add a Photon by its id
    #   Particle.device('f8bbe1e6e69e05c9c405ba1ca504d438061f1b0d').claim
    def remove
      @client.remove_device(self)
    end

    # Rename a Particle device on your account
    #
    # @param name [String] New name for the device
    # @example Change the name of a Photon
    #   Particle.device('blue').rename('red')
    def rename(name)
      @client.rename_device(self, name)
    end

    # Call a function in the firmware of a Particle device
    #
    # @param name [String] Function to run on firmware
    # @param argument [String] Argument string to pass to the firmware function
    # @example Call the thinker digitalWrite function
    #   Particle.device('white_whale').function('digitalWrite', '0')
    def function(name, argument = "")
      @client.call_function(self, name, argument)
    end
    alias_method :call, :function

    # Get the value of a variable in the firmware of a Particle device
    #
    # @param target [String, Device] A device id, name or {Device} object
    # @param name [String] Variable on firmware
    # @return [String, Number] Value from the firmware variable
    # @example Get the battery voltage
    #   Particle.device('mycar').variable('battery') == 12.5
    def variable(name)
      @client.get_variable(self, name)
    end
    alias_method :get, :variable

    # Signal the device to start blinking the RGB LED in a rainbow
    # pattern. Useful to identify a particular device.
    #
    # @param enabled [String] Whether to enable or disable the rainbow signal
    # @return [boolean] true when signaling, false when stopped
    def signal(enabled = true)
      @client.signal_device(self, enabled)
    end

    # Flash new firmware to this device from source code or
    # binary
    #
    # @param file_paths [Array<String>] File paths to send to cloud
    #                                   and flash
    # @param options [Hash] Flashing options
    #                       :binary => true to skip the compile stage
    # @return [OpenStruct] Result of flashing.
    #                :ok => true on success
    #                :errors => String with compile errors
    #                
    def flash(file_paths, options = {})
      @client.flash_device(self, file_paths, options)
    end

    # Compile firmware from source code for this device
    #
    # @param file_paths [Array<String>] File paths to send to cloud
    #                                   and flash
    # @return [OpenStruct] Result of flashing.
    #                :ok => true on success
    #                :errors => String with compile errors
    #                
    def compile(file_paths)
      @client.compile(file_paths, device_id: id)
    end

    # Change the product_id on the device.
    # Use this carefully, it will impact what updates you receive, and
    # can only be used for products that have given their permission
    #
    # @param product_id [String] New product id
    # @param should_update [String] if the device should be
    #                   immediately updated after changing the product_id
    # @return [boolean] true on success
    def change_product(product_id, should_update = false)
      @client.change_device_product(self, product_id, should_update)
    end

    # Update the public key for a device you own
    #
    # @param public_key [String] The public key in PEM format (default
    #                            format generated by openssl)
    # @param algorithm [String] The encryption algorithm for the key
    #                           (default rsa)
    # @return [boolean] true when successful
    def update_public_key(public_key, algorithm = 'rsa')
      @client.update_device_public_key(self, public_key, algorithm)
    end

    def self.list_path
      "v1/devices"
    end

    def self.claim_path
      "v1/devices"
    end

    def self.provision_path
      "v1/devices"
    end

    def self.update_keys_path
      "/v1/provisioning/x"
    end

    def path
      "/v1/devices/#{id_or_name}"
    end

    def function_path(name)
      path + "/#{name}"
    end

    def variable_path(name)
      path + "/#{name}"
    end
  end
end

