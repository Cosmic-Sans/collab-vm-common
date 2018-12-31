@0xb9e188bf95349e81;
using import "Guacamole.capnp".GuacServerInstruction;
using VmId = UInt32;

struct CollabVmServerMessage {
	struct VmInfo {
		id @0 :UInt32;
		name @1 :Text;
		host @2 :Text;
		address @3 :Text;
		operatingSystem @4 :Text;
		uploads @5 :Bool;
		input @6 :Bool;
		ram @7 :UInt8;
		diskSpace @8 :UInt8;
		safeForWork @9 :Bool;
	}

	enum VmStatus {
		stopped @0;
		starting @1;
		running @2;
	}

	struct AdminVmInfo {
		id @0 :UInt32;
		name @1 :Text;
		status @2 :VmStatus;
	}

	struct ChannelChatMessage {
		channel @0 :UInt32;
		message @1 :ChatMessage;
	}

	struct ChannelChatMessages {
		channel @0 :UInt32;
		# Circular buffer
		messages @1 :List(ChatMessage);
		# Index of the oldest chat message
		firstMessage @2 :UInt8;
		count @3 :UInt8;
	}

	struct ChatMessage {
		sender @0 :Text;
		message @1 :Text;
		timestamp @2 :UInt64;
	}

	struct Session {
		sessionId @0 :Data;
		username @1 :Text;
	}

	struct LoginResponse {
		enum LoginResult {
			invalidCaptchaToken @0;
			invalidUsername @1;
			invalidPassword @2;
			twoFactorRequired @3;
			accountDisabled @4;
			success @5; # Only used by server
		}

		result :union {
			session @0 :Session;
			result @1 :LoginResult;
		}
	}

	struct RegisterAccountResponse {
		enum RegisterAccountError {
			usernameTaken @0;
			usernameInvalid @1;
			passwordInvalid @2;
			totpError @3;
			success @4; # Only used by server
		}

		result :union {
			session @0 :Session;
			errorStatus @1 :RegisterAccountError;
		}
	}

	struct ChannelConnectResponse {
		struct ConnectInfo {
			chatMessages @0 :List(ChatMessage);
			description @1 :Text;
		}
		result :union {
			success @0 :ConnectInfo;
			fail @1 :Void;
		}
	}

	struct UsernameChange {
		oldUsername @0 :Text;
		newUsername @1 :Text;
	}

	enum ChatMessageResponse {
		success @0;
		userNotFound @1;
		# The user has too many chat rooms open
		userChatLimit @2;
		# The recipient has too many chat rooms open
		recipientChatLimit @3;
	}

	struct UserInvite {
		id @0 :Data;
		inviteName @1 :Text;
		username @2 :Text;
		admin @3 :Bool;
		#vmHost @5 :Bool;
	}

	message :union {
		vmListResponse @0 :List(VmInfo);
		chatMessage @1 :ChannelChatMessage;
		chatMessages @2 :ChannelChatMessages;
		loginResponse @3 :LoginResponse;
		accountRegistrationResponse @4 :RegisterAccountResponse;
		serverSettings @5 :List(ServerSetting);
		connectResponse @6 :ChannelConnectResponse;
		usernameTaken @7 :Void;
		changeUsername @8 :UsernameChange;
		chatMessageResponse @9 :ChatMessageResponse;
		newChatChannel @10 :ChannelChatMessage;
		reserveUsernameResult @11 :Bool;
		createInviteResult @12 :Data;
		readInvitesResponse @13 :List(UserInvite);
		updateInviteResult @14 :Bool;
		readReservedUsernamesResponse @15 :List(Text);
		readVmsResponse @16 :List(AdminVmInfo);
		readVmConfigResponse @17 :List(VmSetting);
		createVmResponse @18 :UInt32;
		guacInstr @19 :GuacServerInstruction;
		changePasswordResponse @20 :Bool;
	}
}

struct ServerSetting {
	setting :union {
		allowAccountRegistration @0 :Bool = true;
		recaptchaEnabled @1 :Bool;
		recaptchaKey @2 :Text;
		userVmsEnabled @3 :Bool;
		allowUserVmRequests @4 :Bool;
		banIpCommand @5 :Text;
		unbanIpCommand @6 :Text;
	}
}

struct VmSetting {
	struct VmSnapshot {
		name @0 :Text;
		command @1 :Text;
	}

	enum Protocol {
		rdp @0;
		vnc @1;
	}

	enum SocketType {
		# Unix Domain Socket or named pipe on Windows
		local @0;
		tcp @1;
	}

	struct GuacamoleParameter {
		name @0 :Text;
		value @1 :Text;
	}

	setting :union {
		autoStart @0 :Bool;
		name @1 :Text;
		description @2 :Text;
		safeForWork @3 :Bool;
		host @4 :Text;
		operatingSystem @5 :Text;
		ram @6 :UInt8;
		diskSpace @7 :UInt8;
		startCommand @8 :Text;
		stopCommand @9 :Text;
		restartCommand @10 :Text;
		snapshotCommands @11 :List(VmSnapshot);
		# Allow users to take turns controlling the VM
		turnsEnabled @12 :Bool;
		# Number of seconds a turn will last
		turnTime @13 :UInt16 = 20;
		# Allow users to upload files to the VM
		uploadsEnabled @14 :Bool;
		# Number of seconds a user must wait in between uploads
		uploadCooldownTime @15 :UInt16 = 180;
		# Max number of bytes a user is allowed to upload
		maxUploadSize @16 :UInt32 = 15728640; # 15 MiB
		# Allow users to vote for resetting the VM
		votesEnabled @17 :Bool;
		# Number of seconds a vote will last
		voteTime @18 :UInt16 = 60;
		# Number of seconds in between votes
		voteCooldownTime @19 :UInt16 = 600;
		agentAddress @20 :Text;
		protocol @21 :Protocol;
		guacamoleParameters @22 :List(GuacamoleParameter);
	}
}

struct VmConfigModifications {
	id @0 :UInt32;
	modifications @1 :List(VmSetting);
}

struct CollabVmClientMessage {
	message :union { 
		connectToChannel @0 :UInt32;
		chatMessage @1 :ChatMessage;
		vmListRequest @2 :Void;
		loginRequest @3 :Login;
		twoFactorResponse @4 :UInt32;
		accountRegistrationRequest @5 :RegisterAccount;
		changeUsername @6 :Text;
		# Server config
		serverConfigRequest @7 :Void;
		serverConfigModifications @8 :List(ServerSetting);
		serverConfigHidden @9 :Void;
		# VM config
		createVm @10 :List(VmSetting);
		readVms @11 :Void;
		readVmConfig @12 :UInt32;
		updateVmConfig @13 :VmConfigModifications;
		deleteVm @14 :UInt32;
		# Reserved usernames
		createReservedUsername @15 :Text;
		readReservedUsernames @16 :Text;
		deleteReservedUsername @17 :Text;
		# User invites
		createInvite @18 :UserInvite;
		readInvites @19 :Void;
		updateInvite @20 :UserInvite;
		deleteInvite @21 :Data;
		changePasswordRequest @22 :ChangePasswordRequest;
		startVms @23 :List(VmId);
		stopVms @24 :List(VmId);
	}

  struct ChangePasswordRequest {
    oldPassword @0 :Text;
    newPassword @1 :Text;
	}

	struct UserInvite {
		id @0 :Data;
		inviteName @1 :Text;
		username @2 :Text;
		usernameReserved @3 :Bool;
		admin @4 :Bool;
		#vmHost @5 :Bool;
	}

	struct ChatMessage {
		message @0 :Text;
		destination @1 :ChatMessageDestination;
	}

	struct ChatMessageDestination {
		destination :union {
			vm @0 :UInt32;
			newDirect @1 :Text;
			direct @2 :UInt8;
		}
	}
	
	struct Login {
		username @0 :Text;
		password @1 :Text;
		captchaToken @2 :Text;
	}

	struct RegisterAccount {
		username @0 :Text;
		password @1 :Text;
		twoFactorToken @2 :Data;
	}
}
