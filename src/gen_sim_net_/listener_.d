module gen_sim_net_.listener_;

import vibe.core.core : sleep;
import vibe.core.net;
import eventcore.driver	: IOMode;

import core.time;
import gen_sim_net_.connection_;
import std.range.interfaces : InputRange;

import std.experimental.logger;

class Listener {
	this(ushort port) {
		void handleConnection(TCPConnection socket) {
			log("Socket connected");
			auto newConnection = new ListenerConnection(&socket);
			newConnections ~= newConnection;
			while (socket.connected) {
				sleep(1000.msecs);
			}
			newConnection._vibeSocketHandlerStillExists = false;
			log("Socket disconnected");
		}
		void main() {
			listeners = listenTCP(1234, &handleConnection);
			listeners.log;
		}
		main();
	}
	Connection[] getNewConnections() {
		auto toReturn = newConnections;
		newConnections = [];
		return toReturn;
	}
	private {
		TCPListener[]	listeners	;
		Connection[]	newConnections	= []	; 
	}
}

private {
	class ListenerConnection : Connection {
		this (TCPConnection* socket) {
			this.socket = socket;
			this.toMsg = new ToMsg(
				(){
					if (socket.dataAvailableForRead) {
						enum bufferSize = 64;
						ubyte[] buffer = new ubyte[bufferSize];
						auto length = socket.read(buffer, IOMode.once);
						while (length==buffer.length) {
							buffer.length += bufferSize;
							length += socket.read(buffer[$-bufferSize..$], IOMode.once);
						}
						return buffer[0..length];
					}
					return new ubyte[0];
				},
				(buffer=>buffer.length>0?buffer[0]:0)
			);
		}
		private {
			TCPConnection*	socket	;
			ToMsg	toMsg	;
		}
		
		@property bool connected() {
			return _vibeSocketHandlerStillExists && socket.connected;
		}
		bool _vibeSocketHandlerStillExists = true; // should only be changed by the vibe tcp connected handler function (`NetworkMaster.this.handleConnection`)
		
		//---Send
		public {
			void send(const(ubyte[]) msg) {
				if (connected) {
					socket.write(msg);
				}
			}
			alias put = send;
		}
		
		//---Receive
		public {
			InputRange!(const(ubyte)[]) msgs() {
				return new Range(toMsg);
			}
			private class Range : InputRange!(const(ubyte)[]) {
				@property bool empty() {
					if (connected) {
						return toMsg.empty;
					}
					return true;
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
		}
	}
}


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
			msgs ~= buffer[0..msgLen];
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



