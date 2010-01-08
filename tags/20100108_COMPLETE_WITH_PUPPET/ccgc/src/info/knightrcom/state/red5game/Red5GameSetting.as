package info.knightrcom.state.red5game {
    import mx.formatters.SwitchSymbolFormatter;

    /**
     *
     * 红五开局游戏设置
     *
     */
    public class Red5GameSetting {

        public function Red5GameSetting() {
        }

        public static const NO_RUSH:int = 0;

        public static const RUSH:int = 1;

        public static const DEADLY_RUSH:int = 2;

        public static const EXTINCT_RUSH:int = 3;

        public static function getDisplayName(red5GameSetting:int):String {
            var displayName:String = null;
            switch (red5GameSetting) {
                case NO_RUSH:
                    displayName = "不独";
                    break;
                case RUSH:
                    displayName = "独牌";
                    break;
                case DEADLY_RUSH:
                    displayName = "天独";
                    break;
                case EXTINCT_RUSH:
                    displayName = "天外天";
                    break;
                default:
                    throw Error("游戏设置参数错误！");
            }
            return displayName;
        }

        /**
         * 无人选择设置
         *
         * @return
         *
         */
        public static function getNoRushStyle():Array {
            return ["不独", "独牌", "天独", "天外天"];
        }

        /**
         * 有人选择独牌
         *
         * @return
         *
         */
        public static function getRushStyle():Array {
            return ["不独", null, "天独", "天外天"];
        }

        /**
         * 有人选择天独
         *
         * @return
         *
         */
        public static function getDeadlyRushStyle():Array {
            return ["不独", null, null, "天外天"];
        }

    }
}
