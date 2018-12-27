module gen_sim_net_.listener_;

import vibe.core.core : sleep;
import vibe.core.net;
import eventcore.driver	: IOMode;

import core.time;
import gen_sim_net_._to_msg_;
import std.range.interfaces : InputRange;

import std.experimental.logger;

public import gen_sim_net_.connection_;

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
			listeners = listenTCP(port, &handleConnection);
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
					if (connected && socket.dataAvailableForRead) {
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
					socket.write(cast(ubyte)(msg.length+1)~msg);
				}
			}
			alias put = send;
		}
		
		//---Receive
		public {
			InputRange!(const(ubyte)[]) msgs() {
				return createToMsgRange(toMsg);
			}
		}
	}
}




