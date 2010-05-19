package info.knightrcom.assets
{
    public class CommonResource
    {
        public function CommonResource()
        {
        }
        
        /**
         * 游戏大厅背景
         */
        [Embed(source="info/knightrcom/assets/image/common/lobby-background.png")]
        public static const DARK_FLOWER:Class;
        
        /**
         * 自定义Loader
         */
        [Embed(source="info/knightrcom/assets/image/preloader/pathfinder-logo-gray.png")]
        public static const LOGO:Class;

    }
}
