package info.knightrcom.state.pushdownwingame {
    import mx.formatters.SwitchSymbolFormatter;

    /**
     *
     * 推到胡游戏设置
     *
     */
    public class PushdownWinGameSetting {

        public function PushdownWinGameSetting() {
        }

        /** 点炮 */
        public static const NARROW_VICTORY:int = 0;

        /** 自摸 */
        public static const CLEAR_VICTORY:int = 1;

        /** 流局 */
        public static const NOBODY_VICTORY:int = 2;

        public static function getDisplayName(gameResult:int):String {
            var displayName:String = null;
            switch (gameResult) {
                case NARROW_VICTORY:
                    displayName = "点炮";
                    break;
                case CLEAR_VICTORY:
                    displayName = "自摸";
                    break;
                case NOBODY_VICTORY:
                    displayName = "流局";
                    break;
                default:
                    throw Error("游戏设置参数错误！");
            }
            return displayName;
        }

    }
}
