module Coke

  module InvocationExceptionMixin
    @coke_invocation_chain        : String? = nil
    
    def chain
      @coke_invocation_chain
    end

    def chain=(value)
      @coke_invocation_chain = value
    end
  end

end
