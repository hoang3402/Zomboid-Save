--- This is a 1:1 copy of the GameOption class from PZ's MainOptions. This type is used to build
-- quick and dirty UI elements, but is only exposed locally. This needs to be "maintained", as such.
Unpack.GameOption = ISBaseObject:derive("GameOption")

function Unpack.GameOption:new(name, control, arg1, arg2)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.control = control
	o.arg1 = arg1
	o.arg2 = arg2
	if control.isCombobox then
		control.onChange = self.onChangeComboBox
		control.target = o
	end
	if control.isTickBox then
		control.changeOptionMethod = self.onChangeTickBox
		control.changeOptionTarget = o
	end
	if control.isSlider then
		control.targetFunc = self.onChangeVolumeControl
		control.target = o
	end
	return o
end

function Unpack.GameOption:toUI()
	print('ERROR: option "'..self.name..'" missing toUI()')
end

function Unpack.GameOption:apply()
	print('ERROR: option "'..self.name..'" missing apply()')
end

function Unpack.GameOption:resetLua()
	MainOptions.instance.resetLua = true
end

function Unpack.GameOption:onChangeComboBox(box)
	self.gameOptions:onChange(self)
	if self.onChange then
		self:onChange(box)
	end
end

function Unpack.GameOption:onChangeTickBox(index, selected)
	self.gameOptions:onChange(self)
	if self.onChange then
		self:onChange(index, selected)
	end
end

function Unpack.GameOption:onChangeVolumeControl(control, volume)
	self.gameOptions:onChange(self)
	if self.onChange then
		self:onChange(control, volume)
	end
end