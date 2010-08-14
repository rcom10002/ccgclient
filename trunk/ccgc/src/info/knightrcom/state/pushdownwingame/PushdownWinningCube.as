package info.knightrcom.state.pushdownwingame
{

	/**
	 * 
	 */
	public class PushdownWinningCube
	{
		/**
		 * 
		 * @param currentTrack
		 * @param parentTrackResult
		 * @param rootCube
		 * @param parentCube
		 * 
		 */
		public function PushdownWinningCube(currentTrack:String, parentTrackResult:String = null, rootCube:PushdownWinningCube = null, parentCube:PushdownWinningCube = null)
		{
			this.currentTrack = currentTrack;
			this.parentTrackResult = parentTrackResult;
			this.rootCube = rootCube;
			this.parentCube = parentCube;
		}

		/** 父节点 */
		public var parentCube:PushdownWinningCube;

		/** 根节点 */
		private var rootCube:PushdownWinningCube;

		/** 当前要处理的麻将牌序 */
		private var currentTrack:String;

		/** 当前要处理的麻将牌序 */
		public var parentTrackResult:String;

		/** 当前处理结果 */
		public var currentTrackResult:String;

		/** 可以胡牌的路径结果 */
		private var winRoutes:Array = [];

		/**
		 * 
		 * @return 
		 * 
		 */
		public function walkAllRoutes():void {
			// 三张牌以内的情况下，完成胡牌路径
			if (currentTrack.split(",").length < 2) {
				return;
			} else if (currentTrack.split(",").length == 3) {
				if (/^(\w+),\1,\1$/.test(currentTrack)) {
					// 碰
					this.currentTrackResult = currentTrack;
					addWinRoute(this);
				} else {
                    if (/^(EAST|SOUTH|WEST|NORTH|RED|GREEN|WHITE).*$/.test(currentTrack)) {
                        // 跳过无法形成顺子牌的牌型
                        return;
                    }
					if (createChow(currentTrack)) {
						// 吃
						this.currentTrackResult = currentTrack;
						addWinRoute(this);
					}
				}
                return;
			} else if (currentTrack.split(",").length == 2) {
                if (/^(\w+),\1$/.test(currentTrack)) {
    				this.currentTrackResult = currentTrack;
    				addWinRoute(this);
                }
                return;
			}

			// 三张牌以上的情况下，进行递归处理胡牌路径
			var tempRootCube:PushdownWinningCube, optrResult:Array = null;
			if (parentTrackResult == null) {
				tempRootCube = this;
			} else {
				tempRootCube = this.rootCube;
			}
			// 碰
			if (/^(\w+),\1,\1.*$/.test(currentTrack)) {
				optrResult = createPong(currentTrack);
				this.currentTrackResult = optrResult[1];
                new PushdownWinningCube(optrResult[0], optrResult[1], tempRootCube, this).walkAllRoutes();
			}
			// 对子
			if (/^(\w+),\1.*$/.test(currentTrack)) {
				optrResult = createEye(currentTrack);
				this.currentTrackResult = optrResult[1];
                new PushdownWinningCube(optrResult[0], optrResult[1], tempRootCube, this).walkAllRoutes();
			}
			// 顺子
			if (/^(EAST|SOUTH|WEST|NORTH|RED|GREEN|WHITE).*$/.test(currentTrack)) {
				return;
			}
			optrResult = createChow(currentTrack);
			if (optrResult != null) {
				this.currentTrackResult = optrResult[1];
                new PushdownWinningCube(optrResult[0], optrResult[1], tempRootCube, this).walkAllRoutes();
			}
		}

		/**
		 * 
		 * 从既存牌序中创建出一个碰牌
		 * 
		 * @param mahjongs
		 * @return
		 *
		 */
		private function createPong(currentTrack:String):Array
		{
			var result:String = currentTrack.replace(/^((\w+),\2,\2).*$/, "$1");
			return [tidy(currentTrack.replace(new RegExp("^" + result), "")), result];
		}

		/**
		 *
		 * 从既存牌序中创建出一个吃牌
		 * 
		 * @param mahjongs
		 * @return
		 *
		 */
		private function createChow(currentTrack:String):Array
		{
			var result:String = null; // 吃牌序列
			var mahjongPattern:String = currentTrack.replace(/^([WBT]\d).*/, "$1");
			var color:String = mahjongPattern.charAt(0);
			var value:int = int(mahjongPattern.charAt(1));
			var mahjong0:String = color + (value + 0);
			var mahjong1:String = color + (value + 1);
			var mahjong2:String = color + (value + 2);
			var mahjongArray:Array = currentTrack.split(","); // 当前麻将序列
			var mahjongIndex1:int = mahjongArray.indexOf(mahjong1);
			var mahjongIndex2:int = mahjongArray.indexOf(mahjong2);
			if (mahjongIndex1 > 0 && mahjongIndex2 > 0) {
				mahjongArray.splice(mahjongIndex2, 1);
				mahjongArray.splice(mahjongIndex1, 1);
				mahjongArray.shift();
				result = [mahjong0, mahjong1, mahjong2].join(",");
				return [mahjongArray.join(","), result];
			} else {
				return null;
			}
		}

		/**
		 *
		 * 从既存牌序中创建出一个将牌(对子)
		 * 
		 * @param mahjongs
		 * @return
		 *
		 */
		private function createEye(currentTrack:String):Array
		{
			var result:String = currentTrack.replace(/^((\w+),\2).*$/, "$1");
			return [tidy(currentTrack.replace(new RegExp("^" + result), "")), result];
		}

		/**
		 * 
		 * 添加胡牌路径中的叶子节点<br>
		 * 注意：该方法只会被叶子节点调用
		 * 
		 */
		private function addWinRoute(leafCube:PushdownWinningCube):void {
			// 构造完整的牌型
			var groups:Array = [];
			while (leafCube.parentCube != null) {
				// 添加非根节点处理结果
				groups.push(leafCube.currentTrackResult);
				leafCube = leafCube.parentCube;
			}
			// 添加根节点处理结果
			groups.push(leafCube.currentTrackResult);
			// 对结果进行排序
			groups = groups.sort();

			if (groups.length > 5) {
				// 可分解的牌组超过四组，则跳过
				return;
			}
            // 判断胡牌路径是否已经存在
            var winRoute:String = groups.join("~");
            if (this.rootCube.winRoutes.indexOf(winRoute) > -1) {
                return;
            }

            // 保存胡牌路径
			this.rootCube.winRoutes.push(winRoute);
		}

		/**
		 * 
		 * 返回可能的胡牌形式
		 * 
		 * @return 
		 * 
		 */
		public function get winningRoutes():Array {
			return winRoutes;
		}

		/**
		 * 
		 * 整理表现形式
		 *  
		 * @param target
		 * @return 
		 * 
		 */
		private function tidy(target:String):String
		{
			return target.replace(/^,|,$/, "").replace(/,{2,}/, ",");
		}
	}
}
