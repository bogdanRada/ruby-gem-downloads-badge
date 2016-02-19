module MethodicActor
  def on_message(message)
    method, *args = message
    self.send(method, *args)
  end
end