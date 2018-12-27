module gen_sim_net_.connect_to_;

import vibe.core.net;
import eventcore.driver	: IOMode;

import gen_sim_net_._to_msg_;
import std.range.interfaces : InputRange;

import std.experimental.logger;

public import gen_sim_net_.connection_;

Connection connectTo(string ip, ushort port) {
	return new ConnectToConnection(ip,port);
}

private {
	class ConnectToConnection : Connection {
		this(string ip, ushort port) {
			void createSocket() {
				socket = connectTCP(ip, port);
				"Connected to server".log;
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
				////while (s.connected){
				////	import vibe.core.core : sleep;
				////	import core.time;
				////	sleep(1.seconds);
				////}
				////_vibeSocketHandlerStillExists = false;
			}
			////import vibe.core.core : runTask;
			////runTask(&createSocket);
			createSocket();
		}
		
		private {
			TCPConnection	socket;
			ToMsg	toMsg;
		}
		
		@property bool connected() {
			return socket.connected;
		}
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
