module Niceogiri
  module XML

    # Base XML Node
    # All XML classes subclass Node - it allows the addition of helpers
    class Node < Nokogiri::XML::Node
      # Create a new Node object
      #
      # @param [String, nil] name the element name
      # @param [XML::Document, nil] doc the document to attach the node to. If
      # not provided one will be created
      # @return a new object with the name and namespace
      def self.new(name = nil, doc = nil, ns = nil)
        super(name.to_s, (doc || Nokogiri::XML::Document.new)).tap do |node|
          node.document.root = node unless doc
          node.namespace = ns if ns
        end
      end

      # Helper method to read an attribute
      #
      # @param [#to_sym] attr_name the name of the attribute
      # @param [String, Symbol, nil] to_call the name of the method to call on
      # the returned value
      # @return nil or the value
      def read_attr(attr_name, to_call = nil)
        val = self[attr_name.to_sym]
        val && to_call ? val.__send__(to_call) : val
      end

      # Helper method to write a value to an attribute
      #
      # @param [#to_sym] attr_name the name of the attribute
      # @param [#to_s] value the value to set the attribute to
      def write_attr(attr_name, value)
        self[attr_name.to_sym] = value
      end

      # Helper method to read the content of a node
      #
      # @param [#to_sym] node the name of the node
      # @param [String, Symbol, nil] to_call the name of the method to call on
      # the returned value
      # @return nil or the value
      def read_content(node, to_call = nil)
        val = content_from node.to_sym
        val && to_call ? val.__send__(to_call) : val
      end

      # @private
      alias_method :nokogiri_namespace=, :namespace=
      # Attach a namespace to the node
      #
      # @overload namespace=(ns)
      #   Attach an already created XML::Namespace
      #   @param [XML::Namespace] ns the namespace object
      # @overload namespace=(ns)
      #   Create a new namespace and attach it
      #   @param [String] ns the namespace uri
      # @overload namespace=(namespaces)
      #   Createa and add new namespaces from a hash
      #   @param [Hash] namespaces a hash of prefix => uri pairs
      def namespace=(namespaces)
        case namespaces
        when Nokogiri::XML::Namespace
          self.nokogiri_namespace = namespaces
        when String
          self.add_namespace nil, namespaces
        when Hash
          self.add_namespace nil, ns if ns = namespaces.delete(nil)
          namespaces.each do |p, n|
            ns = self.add_namespace p, n
            self.nokogiri_namespace = ns
          end
        end
      end

      # Helper method to get the node's namespace
      #
      # @return [XML::Namespace, nil] The node's namespace object if it exists
      def namespace_href
        namespace.href if namespace
      end

      # Remove a child with the name and (optionally) namespace given
      #
      # @param [String] name the name or xpath of the node to remove
      # @param [String, nil] ns the namespace the node is in
      def remove_child(name, ns = nil)
        child = xpath(name, ns).first
        child.remove if child
      end

      # Remove all children with a given name regardless of namespace
      #
      # @param [String] name the name of the nodes to remove
      def remove_children(name)
        xpath("./*[local-name()='#{name}']").remove
      end

      # The content of the named node
      #
      # @param [String] name the name or xpath of the node
      # @param [String, nil] ns the namespace the node is in
      # @return [String, nil] the content of the node
      def content_from(name, ns = nil)
        child = xpath(name, ns).first
        child.content if child
      end

      # Sets the content for the specified node.
      # If the node exists it is updated. If not a new node is created
      # If the node exists and the content is nil, the node will be removed
      # entirely
      #
      # @param [String] node the name of the node to update/create
      # @param [String, nil] content the content to set within the node
      def set_content_for(node, content = nil)
        if content
          child = xpath(node).first
          self << (child = Node.new(node, self.document)) unless child
          child.content = content
        else
          remove_child node
        end
      end

      alias_method :copy, :dup

      # Inherit the attributes and children of an XML::Node
      #
      # @param [XML::Node] node the node to inherit
      # @return [self]
      def inherit(node)
        set_namespace node.namespace if node.namespace
        inherit_attrs node.attributes
        node.children.each do |c|
          self << (n = c.dup)
          ns = n.namespace_definitions.find { |ns| ns.prefix == c.namespace.prefix }
          n.namespace = ns if ns
        end
        self
      end

      # Inherit a set of attributes
      #
      # @param [Hash] attrs a hash of attributes to set on the node
      # @return [self]
      def inherit_attrs(attrs)
        attrs.each { |name, value| self[name] = value }
        self
      end

      # The node as XML
      #
      # @return [String] XML representation of the node
      def inspect
        self.to_xml
      end

      # Check that a set of fields are equal between nodes
      #
      # @param [Node] other the other node to compare against
      # @param [*#to_s] fields the set of fields to compare
      # @return [Fixnum<-1,0,1>]
      def eql?(o, *fields)
        o.is_a?(self.class) && fields.all? { |f| self.__send__(f) == o.__send__(f) }
      end

      # @private
      def ==(o)
        eql?(o)
      end
    end  # Node
  end # XML
end  # Niceogiri
