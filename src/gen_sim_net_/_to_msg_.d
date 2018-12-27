module gen_sim_net_._to_msg_;

import std.experimental.logger;
import std.range.interfaces : InputRange;

package(gen_sim_net_):

class ToMsg {
	this(ubyte[] delegate() read, ptrdiff_t delegate(ubyte[]) getMsgLen) {
		this.read	= read	;
		this.getMsgLen	= getMsgLen	;
	}
	
	
	@property bool empty() {
		buffer ~= this.read();
		for (ptrdiff_t msgLen=getMsgLen(buffer); msgLen>0; msgLen=getMsgLen(buffer)) {
			if (msgLen>buffer.length) {
				break;
			}
			msgs ~= buffer[1..msgLen];
			buffer = buffer[msgLen..$];
		}
		return msgs.length==0;
	}
	@property const(const(ubyte)[]) front() {
		return msgs[0];
	}
	void popFront() {
		msgs = msgs[1..$];
	}
	
	private {
		ubyte[] delegate()	read	;
		ptrdiff_t delegate(ubyte[])	getMsgLen	;
		
		ubyte[]	buffer	;
		ubyte[][]	msgs	;
	}
}

InputRange!(const(ubyte)[]) createToMsgRange(ToMsg toMsg) {
	class Range : InputRange!(const(ubyte)[]) {
		@property bool empty() {
			return toMsg.empty;
		}
		@property const(ubyte)[] front() {
			return toMsg.front;
		}
		const(ubyte)[] moveFront() {
			return front;
		}
		void popFront() {
			return toMsg.popFront;
		}
		int opApply(scope int delegate(ulong, const(ubyte)[]) dg) {
			size_t i = 0;
			foreach (msg; toMsg) {
				if (dg(i, msg)) {
					return 1;
				}
				i++;
			}
			return 1;
		}
		int opApply(scope int delegate(const(ubyte)[]) dg) {
			foreach (msg; toMsg) {
				if (dg(msg)) {
					return 1;
				}
			}
			return 1;
		}
		private this(ToMsg toMsg) {this.toMsg = toMsg;}
		private ToMsg toMsg;
	}
	return new Range(toMsg);
}

