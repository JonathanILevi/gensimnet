module network_.network_;
import commonImports;

import vibe.core.core : sleep;
import vibe.core.net;
import eventcore.driver	: IOMode;

import core.time;
import std.socket;

import loose_.to_msg_;

class NetworkMaster {
	this() {
		void handleConnection(TCPConnection socket) {
			log("Socket connected");
			auto newNetwork = new Network(&socket);
			newNetworks ~= newNetwork;
			while (socket.connected) {
				sleep(1000.msecs);
			}
			newNetwork._vibeSocketHandlerStillExists = false;
			log("Socket disconnected");
		}
		void main() {
			listeners = listenTCP(1234, &handleConnection);
			listeners.log;
		}
		main();
	}
	auto getNewNetworks() {
		auto toReturn = newNetworks;
		newNetworks = [];
		return toReturn;
	}
	 
	private {
		TCPListener[]	listeners	;
		Network[]	newNetworks	= []	; 
	}
}


class Network {
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
		@property bool empty() {
			if (connected) {
				return toMsg.empty;
			}
			return true;
		}
		@property const(const(ubyte)[]) front() {
			return toMsg.front;
		}
		void popFront() {
			return toMsg.popFront;
		}
	}
	
}


