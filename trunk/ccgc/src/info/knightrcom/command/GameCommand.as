package info.knightrcom.command {

    /**
     *
     * @deprecated
     *
     */
    public class GameCommand extends AbstractCommand {

        public function GameCommand(type:Number, signature:String):void {
            super(type, signature);
            this.number = number;
        }
    }
}
