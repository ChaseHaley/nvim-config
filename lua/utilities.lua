-- Creates an encoded URI key for a directory
function Key_for(dir)
	return vim.uri_encode(vim.fs.normalize(dir), "rfc2396")
end

function Stack()
	return setmetatable({
		_stack = {},
		count = 0,
		push = function(self, obj)
			self.count = self.count + 1
			rawset(self._stack, self.count, obj)
		end,
		pop = function(self)
			self.count = self.count - 1
			return table.remove(self._stack)
		end,
		peek = function(self)
			return rawget(self._stack, self.count)
		end,
	}, {
		__index = function(self, index)
			return rawget(self._stack, index)
		end,
	})
end
