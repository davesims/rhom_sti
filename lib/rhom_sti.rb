#
# A simple STI framework for Rhom::PropertyBag that supports a single-level inheritance model (i.e., children, but no grandchildren).
# 
# It provides a scoped 'find' class method -- calling 'find' on a child of a Rhom model will add a type field condition for the child name.
# Works for hash or SQL formats, i.e.:
#
#    class Base 
#      include Rhom::PropertyBag
#    end
#    
#    class Child < Base
#    end
#  
#    Child.find(:all) # is now the same as calling Base.find(:all, :conditions => {:type => 'Child'}) or Base.find(:all, :conditions => "type = 'Child'")
# 
# The type condition will be appended to any passed-in condtions, in hash or SQL format. The 'type' field is added and set to the child name in 
# Child.new or Child.create. 
#
# NOTE:'name' is overidden because Rho uses the class name to find the registered Rhom source. 'sti_name' is provided so that child classes of Rhom
# models have access to their class name.
#
module Rhom
  module PropertyBag   
    module STI
      module ClassMethods
        # Override find to scope for the sti child type
        def find(*args, &block)
          if args[1] && args[1][:conditions]
            if args[1][:conditions].kind_of? Hash
              args[1][:conditions].merge!({:type => self.sti_name})
            elsif args[1][:conditions].kind_of? String
              args[1][:conditions] << "and type='#{self.sti_name}'"
            end
          else
            (args[1] ||= {})[:conditions] = {:type => self.sti_name}
          end
          super(*args, &block)
        end
        
        # set child type on new instances
        def create(*args)
          (args[0] ||= {}).merge!({'type' => @sti_name})
          super(*args)
        end
        
        def new(*args)
          (args[0] ||= {}).merge!({'type' => @sti_name})
          super(*args)
        end
      
        # override 'name' so that Rho can resolve the source table name to the registered parent (see: RhomObjectFactory.get_source_name)
        def name
          self.superclass.name
        end
      
        # provide a way for child sti classes to access their class name since 'name' is overriden
        def sti_name=(name)
          @sti_name = name
        end
      
        def sti_name
          @sti_name
        end
      end
    end

    module RhomClassMethods
      def inherited(sti_model)
        # sti_model has inherited from a class that itself included Rhom::PropertyBag, therefore this is an STI child class
        sti_name = sti_model.name # store name before it's overidden
        sti_model.extend STI::ClassMethods
        sti_model.sti_name = sti_name
      end
    end

    def self.included(model)
      model.extend RhomClassMethods
      model.extend PropertyBag
    end
  end
end