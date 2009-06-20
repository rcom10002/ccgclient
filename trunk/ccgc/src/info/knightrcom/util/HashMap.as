package info.knightrcom.util
{
	/**
	 * <p>将键映射到值的对象。一个映射不能包含重复的键；每个键最多只能映射一个值</p>
	 * <p>它的实现类有以下的类：</p>
	 * @author soda(弃天笑)
	 */
	import flash.utils.Dictionary;

	public class HashMap implements IMap
	{
		private var _keys:Array=null;
		private var props:Dictionary=null;

		public function HashMap()
		{
			this.clear();
		}

		public function clear():void
		{
			this.props=new Dictionary();
			this._keys=new Array();
		}

		public function containsKey(key:Object):Boolean
		{
			return this.props[key] != null;
		}

		public function containsValue(value:Object):Boolean
		{
			var result:Boolean=false;
			var len:uint=this.size();
			if (len > 0)
			{
				for (var i:uint=0; i < len; i++)
				{
					if (this.props[this._keys[i]] == value)
					{
						result=true;
					}
					else
					{
						result=false;
					}
				}
			}
			else
			{
				result=false;
			}
			return result;
		}

		public function get(key:Object):Object
		{
			return this.props[key];
		}

		public function put(key:Object, value:Object):Object
		{
			var result:Object=null;
			if (this.containsKey(key))
			{
				result=this.get(key);
				this.props[key]=value;
			}
			else
			{
				this.props[key]=value;
				this._keys.push(key);
			}
			return result;
		}

		public function remove(key:Object):Object
		{
			var result:Object=null;
			if (this.containsKey(key))
			{
				delete this.props[key];
				var index:int=this._keys.indexOf(key);
				if (index > -1)
				{
					this._keys.splice(index, 1);
				}
			}
			return result;
		}

		public function putAll(map:IMap):void
		{
			this.clear();
			var len:uint=map.size();
			if (len > 0)
			{
				var arr:Array=map.keys();
				for (var i:uint=0; i < len; i++)
				{
					this.put(arr[i], map.get(arr[i]));
				}
			}
		}

		public function size():Number
		{
			return this._keys.length;
		}

		public function isEmpty():Boolean
		{
			return this.size() < 1;
		}

		public function values():Array
		{
			var result:Array=new Array();
			var len:Number=this.size();
			if (len > 0)
			{
				for (var i:Number=0; i < len; i++)
				{
					result.push(this.props[this._keys[i]]);
				}
			}
			return result;
		}

		public function keys():Array
		{
			return this._keys;
		}

	}
}