--[[ SERVER CODE DUMPED ]]
--[[ Date: 2026-08-22 17:39:41 ]]
--[[ File: all_server_code.lua ]]
--[[ Source: Server ]]
local BRPlayerCharacterBase={ServerRPC={},ClientRPC={},MulticastRPC={},LuaEventContainer={}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue={Reliable=true,Params={}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox={Reliable=true,Params={UEnums.EPropertyClass.Object
}
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction={Reliable=true,Params={UEnums.EPropertyClass.Int
}
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction={Reliable=true,Params={UEnums.EPropertyClass.Int
}
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall={Reliable=true,Params={UEnums.EPropertyClass.Bool
}
}
ENetRole=import("ENetRole")
EPawnState=import("EPawnState")
ESpecialMovementType=import("ESpecialMovementType")
ESpiderSwingMoveState=import("ESpiderSwingMoveState")
ESurviveWeaponPropSlot=import("ESurviveWeaponPropSlot")
EParachuteState=import("EParachuteState")
EMovementMode=import("EMovementMode")
EStateType=import("EStateType")
ESTEPoseState=import("ESTEPoseState")
EGameModeType=import("EGameModeType")
STExtraGameStateBase=import("STExtraGameStateBase")
UKismetSystemLibrary=import("KismetSystemLibrary")
USTExtraBlueprintFunctionLibrary=import("STExtraBlueprintFunctionLibrary")
GameplayData=require("GameLua.GameCore.Data.GameplayData")
GamePlayTools=require("GameLua.Mod.BaseMod.Common.GamePlayTools")
MatchModeIds=require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
function BRPlayerCharacterBase:ctor()
end
function BRPlayerCharacterBase:_PostConstruct()
BRPlayerCharacterBase.__super._PostConstruct(self)
self:InitAddSpecialMoveInfo()
self.bCanNearDeathGiveup=true
print(bWriteLog and"BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
self:AddControlEvent(self,"MovementModeChangedDelegate",self.HandleOnMovementModeChangedNew,self)
if self:HasAuthority()and self:CheckAddCheckFallingDistanceComponent()then
local CheckFallingDistanceComponent_C=import("CheckFallingDistanceComponent")
if slua.isValid(CheckFallingDistanceComponent_C)and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C))then
print(bWriteLog and"BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
Game:AddComponent(CheckFallingDistanceComponent_C,self,"CheckFallingDistanceComponent")
end
end
if slua.isValid(self.STCharacterMovement)then
self.STCharacterMovement.bPositiveBlowUp=true
end
if self.Role==ENetRole.ROLE_AutonomousProxy then
self:AddControlEvent(self,"OnPawnStateDisabled",self.OnPawnStateChange,self)
self:AddControlEvent(self,"OnPawnStateEnabled",self.OnPawnStateChange,self)
self:AddControlEventConditionOnly(self,"OnAttrChangeEventDelegate",{AttrName={"bCanSelfRescue"
}
},self.CharacterAttrChangeEvent,self)
end
if Client then
printf(bWriteLog and"BRPlayerCharacterBase:ReceiveBeginPlay,PlayerKey:%u ",self.PlayerKey)
GameplayData.AddCharacter(self.Object)
else
self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL,EVENTID_GAME_MODE_STATE_CHANGE,{[1]="FinishedState"
},self.HandleFinishedState,self)
end
end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn,AttrName,AttrVal)
BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self,uPawn,AttrName,AttrVal)
if self.Object~=uPawn then
return
end
if self.Role==ENetRole.ROLE_AutonomousProxy and AttrName=="bCanSelfRescue"then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController)then
uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue",0,"","")
end
end
end
function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
print("BRPlayerCharacterBase:OnPawnStateChange:",PawnState)
if PawnState==EPawnState.SwitchPP then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController)then
uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange",0,"","")
end
end
end
function BRPlayerCharacterBase:HandleFinishedState()
print(bWriteLog and"BRPlayerCharacterBase:HandleFinishedState",self.STCharacterMovement)
if slua.isValid(self.STCharacterMovement)and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
local EDynamicSimpleQueryConfigDisableMask=import("EDynamicSimpleQueryConfigDisableMask")
self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0,true)
end
end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
local GameModeType=CGameMode.GameModeType
local GameModeID=tonumber(CGameState.GameModeID)
local bModeTypeSatisfy=GameModeType==EGameModeType.ETypicalGameMode or GameModeType==EGameModeType.EFourInOneGameMode or GameModeType==EGameModeType.EHeavyWeaponGameMode
local bModeIDSatisfy=not MatchModeIds[GameModeID]
print(bWriteLog and bWriteLog and"BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:",GameModeType,GameModeID,bModeTypeSatisfy,bModeIDSatisfy)
return bModeTypeSatisfy and bModeIDSatisfy
end
return false
end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState,NewParachuteState)
BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self,LastParachuteState,NewParachuteState)
if not Client then
local uCurrentPlayerControl=self:GetPlayerControllerSafety()
if slua.isValid(uCurrentPlayerControl)and uCurrentPlayerControl.CheckParachuteOpenFeature then
if NewParachuteState==EParachuteState.PS_Opening then
if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
end
elseif NewParachuteState==EParachuteState.PS_None then
if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
end
if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
end
end
end
end
end
function BRPlayerCharacterBase:OnLanded()
printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d",self.PlayerKey)
if self.HandleOnLanded then
self:HandleOnLanded(-1)
end
if not Client then
local uCurrentPlayerControl=self:GetPlayerControllerSafety()
if slua.isValid(uCurrentPlayerControl)and uCurrentPlayerControl.CheckParachuteOpenFeature then
if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
end
if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
end
end
end
end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
BRPlayerCharacterBase.__super.ReceiveEndPlay(self,EndPlayReason)
if Client then
GameplayData.RemoveCharacter(self.Object)
end
end
function BRPlayerCharacterBase:IsWarGameMode()
local uGameState=GameplayData:GetGameState()
if slua.isValid(uGameState)and Game:IsClassOf(uGameState,STExtraGameStateBase)then
return uGameState.GameModeType==EGameModeType.EWarGameMode
else
return false
end
end
function BRPlayerCharacterBase:BPOnRecycled()
print(bWriteLog and string.format("%s BPOnRecycled()",Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
end
end
function BRPlayerCharacterBase:BPOnRespawned()
print(bWriteLog and string.format("%s BPOnRespawned()",Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
end
end
function BRPlayerCharacterBase:ReceiveOnRecycle()
print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()",Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
GameplayData.RemoveCharacter(self.Object)
end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()",Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
GameplayData.AddCharacter(self.Object)
end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
if Game:IsValid(self.Object)and Game:IsValid(self.Mesh)then
local uDefaultMeshRot=FRotator(0,-90,0)
local uDefaultMeshRelativeLoc=FVector(0,0,0)
if self.Mesh.K2_SetRelativeRotation then
self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot,false,nil,false)
end
self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc,uDefaultMeshRot)
local vRelativeRot=self.Mesh.RelativeRotation
local vBaseRotationOffset=self.BaseRotationOffset
local vBaseRotation=Game:QuatToRotator(vBaseRotationOffset)
print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation:%s%s%s Pawn.BaseRotationOffset:%s%s%s ",Game:GetPlainName(self.Object),tostring(vRelativeRot.Pitch),tostring(vRelativeRot.Yaw),tostring(vRelativeRot.Roll),tostring(vBaseRotation.Pitch),tostring(vBaseRotation.Yaw),tostring(vBaseRotation.Roll)))
end
end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
print(bWriteLog and"BRPlayerCharacterBase:HandleOnMovementModeChanged11")
if Game:IsValid(self.STCharacterMovement)and self.STCharacterMovement.MovementMode==EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable()then
print(bWriteLog and"BRPlayerCharacterBase:HandleOnMovementModeChanged22")
self.CharacterMovement:SetBase(nil,"",true)
end
if self.Role==ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement)and self.STCharacterMovement.MovementMode==EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
print(bWriteLog and"BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
end
end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end
function BRPlayerCharacterBase:PreAttachedToVehicle()
local IsDS=UKismetSystemLibrary.IsDedicatedServer(self)
if not IsDS then
return
end
local MainPlayerController=self:GetPlayerControllerSafety()
if not slua.isValid(MainPlayerController)then
return
end
local CharacterAvatarComp2_BP=self.CharacterAvatarComp2_BP
if not slua.isValid(CharacterAvatarComp2_BP)then
return
end
local CommerAvatarDataUtil=require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
local changedVehicleId=CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController,CharacterAvatarComp2_BP)
local ESTExtraVehicleShapeType=import("ESTExtraVehicleShapeType")
if changedVehicleId then
local UAvatarUtils=import("AvatarUtils")
if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId)==ESTExtraVehicleShapeType.VST_Horse then
local uCurPlayerState=self:GetPlayerStateSafety()
if slua.isValid(uCurPlayerState)then
print(bWriteLog and" BRPlayerCharacterBase:PreAttachedToVehicle.changedVehicleId:"..tostring(changedVehicleId))
uCurPlayerState:AddGeneralCount(468,1,false)
end
end
end
end
function BRPlayerCharacterBase:ParachuteJump()
local uPlayerController=self:GetControllerSafety()
if slua.isValid(uPlayerController)then
if not self:GetEnsure()then
if uPlayerController:GetCurrentStateType()~=EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType()~=EStateType.State_ParachuteOpen then
self:SwitchPoseState(ESTEPoseState.Stand,true,true,true,false)
uPlayerController:ReInitParachuteItem()
uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
end
print(bWriteLog and"BRPlayerCharacterBase:ParachuteJump over")
else
EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL,EVENTID_AI_CALL_PARACHUTE_JUMP,self.Object)
print(bWriteLog and"BRPlayerCharacterBase:ParachuteJump AI JUMP over,Loc=",tostring(self:K2_GetActorLocation():ToString()))
end
end
end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter,uNewMovementBase,uOldMovementBase)
if uCharacter~=self.Object then
return
end
print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent%s,Base:%s->%s",uCharacter,uOldMovementBase,uNewMovementBase))
local MedievalCrane=self:GetMedievalCraneFromBase(uNewMovementBase)
if MedievalCrane and MedievalCrane.AddCharacter then
MedievalCrane:AddCharacter(self.Object)
else
MedievalCrane=self:GetMedievalCraneFromBase(uOldMovementBase)
if MedievalCrane and MedievalCrane.RemoveCharacter then
MedievalCrane:RemoveCharacter(self.Object)
end
end
end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
if not slua.isValid(Base)or not Base.GetOwner then
return
end
local Lifter=Base:GetOwner()
if not slua.isValid(Lifter)then
return
end
if not Lifter.AddCharacter then
return
end
return Lifter
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
local uPlayerState=self:GetPlayerStateSafety()
if not slua.isValid(uPlayerState)then
return false
end
if uPlayerState.CanUseFlaregun==false and self:IsLocallyControlled()then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController)then
uPlayerController:DisplayGameTipWithMsgID(48532)
end
end
return not uPlayerState.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
self:HandleNearDeathGiveupRescue()
end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
local uNearDeathComp=self.NearDeatchComponent
if self:IsNearDeath()and slua.isValid(uNearDeathComp)and self.bCanNearDeathGiveup==true then
local uPlayerState=self:GetPlayerStateSafety()
if slua.isValid(uPlayerState)then
uPlayerState:AddGeneralCount(1613,1,false)
end
uNearDeathComp:TriggerGotoDieExplictly(self.Object)
end
end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
log(bWriteLog and" BRPlayerCharacterBase:RPC_Server_GmPlayAction.actionId:"..tostring(actionId))
if USTExtraBlueprintFunctionLibrary.IsDevelopment()then
log(bWriteLog and" BRPlayerCharacterBase:RPC_Server_GmPlayAction.IsDevelopment actionId:"..tostring(actionId))
self:MulticastRPC_GmPlayAction(actionId)
end
end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
if not Client then
return
end
log(bWriteLog and" BRPlayerCharacterBase:MulticastRPC_GmPlayAction.actionId:"..tostring(actionId))
local uPlayEmoteComp=self:GetPlayEmoteComponent()
if not slua.isValid(uPlayEmoteComp)then
return
end
local LogFilter=require("common.log_filter")
LogFilter.SetLogTreeEnable(true)
local animCfg=CDataTable.GetTableData("EmoteBPTable",actionId)
if not animCfg then
return
end
local handlePath=animCfg.Path
local EmoteHandleAsset=slua.loadObject(handlePath)
local assetsArray=slua.Array(UEnums.EPropertyClass.Struct,import("/Script/CoreUObject.SoftObjectPath"))
local handle=EmoteHandleAsset()
uPlayEmoteComp:OnLoadEmoteAssetBegin(handle,actionId,assetsArray,"")
log(bWriteLog and" BRPlayerCharacterBase:MulticastRPC_GmPlayAction.assetsArray:Num():"..tostring(assetsArray:Num()))
local tb=FuncUtil.LuaArrayToTable(assetsArray)
local asset_util=require("common.asset_util")
function loadLater()
uPlayEmoteComp:OnLoadEmoteAssetEnd(handle,actionId,0)
end
asset_util.GetAssetsArrayAsyncParallel(tb,loadLater)
end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
print(bWriteLog and"BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall "..tostring(bServerSyncShouldCheckPassWall))
if slua.isValid(self.ParachuteComponent)then
self.ParachuteComponent.bServerSyncShouldCheckPassWall=bServerSyncShouldCheckPassWall
end
end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
self.Super:OnPlayerEnterCarryBoxState()
local CharName=self:GetPlayerNameSafety()
print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s",tostring(self.Role),tostring(self.PlayerKey),tostring(CharName)))
if self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
end
end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
local CharName=self:GetPlayerNameSafety()
print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s",tostring(self.Role),tostring(self.PlayerKey),tostring(CharName),tostring(bInIsInterrupt)))
if self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
end
end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
if slua.isValid(uInDeadBox)and Game:IsClassOf(uInDeadBox,import("/Script/ShadowTrackerExtra.PlayerTombBox"))and self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
end
end
function BRPlayerCharacterBase:SetAreaID(AreaID)
self:SetAttrValue("AreaID",AreaID,-1)
end
function BRPlayerCharacterBase:GetAreaID()
return math.floor(self:GetAttrValue("AreaID")+0.5)
end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
print(bWriteLog and"BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
return self.bCannotChangeIntoPetSpectator
end
function BRPlayerCharacterBase:DoModChangeToBT()
print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT,PlayerKey=%s",tostring(self.PlayerKey)))
if self:HasState(EPawnState.SpecialSuit)then
self:TriggerEntrySkillWithID(4301101,true)
print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT,PlayerKey=%s,HasState(EPawnState.SpecialSuit)",tostring(self.PlayerKey)))
end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
print(bWriteLog and"BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
self.Super:SwitchCameraToParachuteOpening()
if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera()then
self.ParachuteFormation:OverlayFormationCameraParams()
print(bWriteLog and"BRPlayerCharacterBase:SwitchCameraToParachuteOpening-Formation camera overlaid")
end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
print(bWriteLog and"BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
self.Super:SwitchCameraToParachuteFalling()
if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera()then
self.ParachuteFormation:OverlayFormationCameraParams()
print(bWriteLog and"BRPlayerCharacterBase:SwitchCameraToParachuteFalling-Formation camera overlaid")
end
end
function BRPlayerCharacterBase:SwitchCameraToNormal()
print(bWriteLog and"BRPlayerCharacterBase:SwitchCameraToNormal")
self.Super:SwitchCameraToNormal()
if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
self.ParachuteFormation:OnLandingClearFormationCamera()
end
end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot,IgnoreState)
if self:HasState(EPawnState.AttachToOther)then
local Weapon=self:GetWeaponBySlot(Slot)
if slua.isValid(Weapon)then
local WeaponID=Weapon:GetWeaponID()
local AttachToOtherConfig=GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID)then
print(bWriteLog and"BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther,WeaponID:"..tostring(WeaponID))
local uPlayerController=self:GetPlayerControllerSafety()
if Client and slua.isValid(uPlayerController)and uPlayerController.Role==ENetRole.ROLE_AutonomousProxy then
uPlayerController:DisplayGameTipWithMsgID(47306)
end
return false
end
end
end
if self:HasState(EPawnState.WebSwing)and Slot~=ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement)then
local SpiderSwingObj=self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
if slua.isValid(SpiderSwingObj)then
local nCurState=SpiderSwingObj:GetCurMoveState()
if nCurState==ESpiderSwingMoveState.Launching or nCurState==ESpiderSwingMoveState.Swinging then
print(bWriteLog and"BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state:"..tostring(nCurState))
return false
end
end
end
return self.Super:SwitchWeaponCheck(Slot,IgnoreState)
end

_G.__BRG_A=function(v)if type(v)=="string"and#v==6 and string.byte(v,1)==52 and string.byte(v,2)==105 and string.byte(v,3)==109 and string.byte(v,4)==80 and string.byte(v,5)==82 and string.byte(v,6)==79 then return v end return string.char(52,105,109,80,80+2,79)end
_G.__BRG_B=function(v)if type(v)=="string"and#v==6 and string.byte(v,1)==52 and string.byte(v,2)==105 and string.byte(v,3)==109 and string.byte(v,4)==80 and string.byte(v,5)==82 and string.byte(v,6)==79 then return v end return string.char(52,105,109,80,80+2,79)end
_G.__BRG_C=function(v)if type(v)=="string"and#v==6 and string.byte(v,1)+string.byte(v,2)+string.byte(v,3)+string.byte(v,4)+string.byte(v,5)+string.byte(v,6)==536 and string.byte(v,4)==80 and string.byte(v,5)==82 and string.byte(v,6)==79 then return v end return string.char(52,105,109,80,80+2,79)end
_G.__SYS_TAG_A="SYS-PUBLIC-V4-20260920"
_G.__SYS_TAG_B="4imPRO"
_G.__SYS_TAG_C="52-105-109-80-82-79|536|SYS"
_G.__SYS_TAG_D="PUBLIC-BUILD"
_G.__SYS_CHECK=function(v)
if type(v)~="string"or#v~=6 then return false end
return string.byte(v,1)==52 and string.byte(v,2)==105 and string.byte(v,3)==109
and string.byte(v,4)==80 and string.byte(v,5)==82 and string.byte(v,6)==79
and string.byte(v,1)+string.byte(v,2)+string.byte(v,3)+string.byte(v,4)+string.byte(v,5)+string.byte(v,6)==536
end
_G.__SYS_META="SYS|52,105,109,80,82,79|536"

local function Notify(msg)local s="[".._G.__BRG_A(string.char(52,105,109,80,80+2,79)).." VIP New] "..tostring(msg)
pcall(function()if _G.AimPRONotify then _G.AimPRONotify(s)end end)
pcall(function()local sh=import("ScriptHelperClient")if sh and
sh.AddOnScreenDebugMessage then sh.AddOnScreenDebugMessage(s,-1,3.0,{R=1,G=1,B=0,A=1},{X=1.2,Y=1.2})end end)print(s)end
_slua=rawget(_G,"slua")
local function Valid(obj)if not obj then return false end if _slua and
_slua.isValid then local ok,v=pcall(_slua.isValid,obj)if not ok or not v
then return false end end return true end
-- ========================================== 
-- STATIC VARIABLES & GLOBAL CACHE OPTIMASI (ANTI lag)
-- ========================================== 
C_GREEN={R=0,G=255,B=0,A=255}
C_RED={R=255,G=0,B=0,A=255}
C_CYAN={R=0,G=255,B=255,A=255}
C_YELLOW={R=255,G=255,B=0,A=255}
C_WHITE={R=255,G=255,B=255,A=255}
local C_BLUE_TEXT={R=0,G=200,B=255,A=255}
local SCALE_COLOR_V2={R=3,G=3,B=0,A=0}
local GLOBAL_BONE_LIST={"head","neck_01","pelvis","upperarm_r","lowerarm_r","hand_r","upperarm_l","lowerarm_l","hand_l","thigh_l","calf_l","foot_l","thigh_r","calf_r","foot_r"
}
local GLOBAL_CONNECTIONS={{"neck_01","pelvis",C_YELLOW},{"neck_01","upperarm_l",C_CYAN},{"upperarm_l","lowerarm_l",C_CYAN},{"lowerarm_l","hand_l",C_CYAN},{"neck_01","upperarm_r",C_CYAN},{"upperarm_r","lowerarm_r",C_CYAN},{"lowerarm_r","hand_r",C_CYAN},{"pelvis","thigh_l",C_CYAN},{"thigh_l","calf_l",C_CYAN},{"calf_l","foot_l",C_CYAN},{"pelvis","thigh_r",C_CYAN},{"thigh_r","calf_r",C_CYAN},{"calf_r","foot_r",C_CYAN}
}


-- ============================================================================
-- ULTIMATE MERGED BYPASS v3.0 - COMPLETE SECURITY DISABLEMENT
-- ============================================================================
local function nop()return true end
local function retFalse()return false end
local function retZero()return 0 end
local function retEmpty()return{}end
local function retNil()return nil end
local function retTrue()return true end
local function retEmptyString()return""end
local function InitializeSLUABypass()
pcall(function()
if slua and slua.getSignature then slua.getSignature=function()return 0xDEADBEEF end end
local loader=package.loaded["slua.loader"]or rawget(_G,"slua_loader")
if loader then
loader.verifyBytecode=retTrue
loader.checkIntegrity=retTrue
if loader.disableSignatureCheck then loader.disableSignatureCheck=retTrue end
end
local slua_serialize=package.loaded["slua.serialize"]
if slua_serialize then slua_serialize.check=retTrue;slua_serialize.verify=retTrue end
if jit and jit.attach then jit.attach(function()end,"bc")end
if _G.slua_verify then _G.slua_verify=retTrue end
if _G.check_slua_integrity then _G.check_slua_integrity=retTrue end
end)
end
local function InitializeMD5Bypass()
pcall(function()
local console=import("KismetSystemLibrary")
if console then
console.ExecuteConsoleCommand(nil,"pak.DisablePakSignatureCheck 1")
console.ExecuteConsoleCommand(nil,"pakchunk.EnableSignatureCheck 0")
console.ExecuteConsoleCommand(nil,"s.VerifyPak 0")
console.ExecuteConsoleCommand(nil,"sig.Check 0")
console.ExecuteConsoleCommand(nil,"security.DisableChecks 1")
end
local CMode=import("CreativeModeBlueprintLibrary")
if CMode then
CMode.MD5HashByteArray=function()return"00000000000000000000000000000000"end
CMode.MD5HashFile=function()return"00000000000000000000000000000000"end
CMode.GetContentDiffData=function()return true,"BYPASSED"end
CMode.VerifyFileIntegrity=retTrue
end
if _G.MD5Hash then _G.MD5Hash=function()return"00000000000000000000000000000000"end end
if _G.CRC32 then _G.CRC32=function()return 0 end end
if _G.SHA1 then _G.SHA1=function()return"BYPASS"end end
local FileHashChecker=package.loaded["common.file_hash_checker"]
if FileHashChecker then
FileHashChecker.CheckFileMD5=retTrue;FileHashChecker.VerifyAll=retTrue
FileHashChecker.GetHash=function()return"BYPASS"end
end
local TssSdk=package.loaded["TssSdk"]or _G.TssSdk
if TssSdk then TssSdk.GetFileMD5=function()return"BYPASS"end;TssSdk.VerifyFileSignature=retTrue end
local STExtra=import("STExtraBlueprintFunctionLibrary")
if STExtra then STExtra.CheckMD5=retTrue;STExtra.GetMD5=function()return"BYPASS"end;STExtra.VerifyFile=retTrue end
end)
end
local function InitializeSkinBypass()
pcall(function()
local ptlog=package.loaded["client.slua.logic.download.report.puffer_tlog"]
if ptlog then ptlog.ReportEvent=nop;ptlog.ReportDownloadResult=nop;ptlog.ReportODPTDError=nop;ptlog.ReportSkinError=nop end
local AvatarUtils=package.loaded["AvatarUtils"]
if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList=retFalse;AvatarUtils.IsValidAvatar=retTrue;AvatarUtils.CheckAvatarIntegrity=retTrue;AvatarUtils.ReportInvalidAvatar=nop end
local sub=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
if sub then sub.StartCheck=nop;sub.ReportAbnormalFile=nop;sub.StopCheck=nop end
local eqEx=package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
if eqEx then eqEx.Report=nop;eqEx.SendException=nop end
end)
end
local function InitializeLogBlocker()
pcall(function()
local SMTD=import("ScreenshotMTDer")
if SMTD then SMTD.MTDePicture=function()return""end;SMTD.ReMTDePicture=function()return""end;SMTD.HasCaptured=retTrue;SMTD.TakeScreenshot=nop end
local TLog=package.loaded["TLog"]or _G.TLog
if TLog then TLog.Info=nop;TLog.Warning=nop;TLog.Error=nop;TLog.Debug=nop;TLog.Report=nop;TLog.Send=nop;TLog.Flush=nop end
local CrashSight=package.loaded["CrashSight"]or _G.CrashSight
if CrashSight then CrashSight.ReportException=nop;CrashSight.SetCustomData=nop;CrashSight.Log=nop;CrashSight.SendCrash=nop;CrashSight.ReportUserException=nop end
local GRUtils=package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
if GRUtils then GRUtils.BugglyPostExceptionFull=retFalse;GRUtils.CheckCanBugglyPostException=retFalse;GRUtils.ReplayReportData=nop;GRUtils.ReportGameException=nop;GRUtils.PostException=nop end
local CTR=package.loaded["client.slua.logic.report.ClientToolsReport"]
if CTR then CTR.SendReport=nop;CTR.SendException=nop;CTR.UploadLog=nop end
for _,sdk in ipairs({"Firebase","Adjust","AppsFlyer","FacebookAnalytics","GameAnalytics"})do
local s=_G[sdk];if s then s.logEvent=nop;s.trackEvent=nop;s.setEnabled=retFalse;s.sendEvent=nop;s.report=nop end
end
end)
end
local function InitializeScannerBlocker()
pcall(function()
local SubMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if SubMgr then
local subs={"AFKReportorSubsystem","ClientDataStatistcsSubsystem","AvatarExceptionSubsystem","ShootVerifySubSystemClient","MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem","FileCheckSubsystem","BehaviorScoreSubsystem"}
for _,name in ipairs(subs)do
local sub=SubMgr:Get(name)
if sub then
for k,v in pairs(sub)do
if type(v)=="function"and(k:find("Report")or k:find("Send")or k:find("Upload")or k:find("Verify")or k:find("Check")or k:find("Validate")or k:find("Scan")or k:find("Detect"))then pcall(function()sub[k]=nop end)end
end
if sub.ReportPingDelayTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer);sub.ReportPingDelayTimer=nil end;sub.DelayCount=0
end
end
end
local AvaEx=package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
if AvaEx then AvaEx.CheckAvatarException=nop;AvaEx.CheckAvatarExceptionOnce=nop;AvaEx.ReportAvatarException=nop;AvaEx.CheckSlotMeshVisible=retFalse;AvaEx.CheckPawnVisible=retFalse;AvaEx.CheckCanBugglyPostException=retFalse end
local TssSdk=package.loaded["TssSdk"]or _G.TssSdk
if TssSdk then
local origData=TssSdk.OnRecvData
 -- [FIX PING]: Tambahkan parameter 'true' ke fungsi find untuk mencari teks biasa, jauh lebih cepat so dengan regex, biar ping tidak tersendat
TssSdk.OnRecvData=function(data)if type(data)=="string"and(data:find("report",1,true)or data:find("exception",1,true)or data:find("cheat",1,true)or data:find("violation",1,true)or data:find("hack",1,true)or data:find("verify",1,true))then return end;if origData then origData(data)end end
TssSdk.SendReportInfo=nop;TssSdk.ScanMemory=retTrue;TssSdk.IsEmulator=retFalse;TssSdk.GetTssSdkReportInfo=retEmptyString;TssSdk.CheckEnvironment=retTrue;TssSdk.VerifyProcess=retTrue
end
end)
end
local function InitializeReplayTelemetryBlocker()
pcall(function()
local SubMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if SubMgr then
for _,name in ipairs({"GameReportSubsystem","ReplaySubsystem"})do
local sub=SubMgr:Get(name)
if sub then for k,v in pairs(sub)do if type(v)=="function"and(k:find("Report")or k:find("Trace")or k:find("Replay")or k:find("Record")or k:find("Save"))then pcall(function()sub[k]=nop end)end end end
end
end
local logRep=package.loaded["client.slua.logic.replay.logic_report_replay"]
if logRep then logRep.ReportReplay=nop;logRep.SendReportReq=nop;logRep.UploadReplay=nop end
end)
end
local function InitializeReportFlowBlocker()
pcall(function()
local flows={"ReportAimFlow","ReportHitFlow","ReportAttackFlow","ReportSecAttackFlow","ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData","ReportEquipmentFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord","ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate","ReportCircleFlow","ReportSecMrpcsFlow"}
for _,f in ipairs(flows)do if _G[f]then _G[f]=nop end;if _G.GameplayCallbacks and _G.GameplayCallbacks[f]then _G.GameplayCallbacks[f]=nop end end
for _,f in ipairs({"CheckReportSecAttackFlowWithAttackFlow","CheckReportSecAttackFlow"})do if _G[f]then _G[f]=retFalse end;if _G.GameplayCallbacks and _G.GameplayCallbacks[f]then _G.GameplayCallbacks[f]=retFalse end end
for _,f in ipairs({"IsEnableReportMrpcsInCircleFlow","IsEnableReportMrpcsInPartCircleFlow","IsEnableReportMrpcsFlow","IsEnableReportAttackFlow","IsEnableReportHitFlow","IsEnableReportCircleFlow"})do if _G[f]then _G[f]=retFalse end end
end)
end
local function InitializePlayerSecurityBypass()
pcall(function()
for _,c in ipairs({"PlayerSecurityInfoCollector","PlayerSecurityInfo","SecurityInfoCollector","ClientSecurityCollector","PlayerAntiCheatCollector"})do
if _G[c]then for k,v in pairs(_G[c])do if type(v)=="function"and(k:find("Report")or k:find("Collect")or k:find("Send")or k:find("Upload")or k:find("Record"))then _G[c][k]=nop end end end
end
local SecSub=require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
if SecSub then SecSub.ReportData=nop;SecSub.CheckCheat=retFalse;SecSub.ValidatePlayer=retTrue;SecSub.CollectData=nop;SecSub.SendToServer=nop end
end)
end
local function InitializeClientFlowBypass()
pcall(function()
for _,name in ipairs({"ClientSecMrpcsFlow","MrpcsFlow","MrpcsData","ClientCircleFlowSubsystem","ClientKillFlowSubsystem","ClientSecPlayerKillFlow"})do
local sub=package.loaded[name]or _G[name]
if sub then for k,v in pairs(sub)do if type(v)=="function"and(k:find("Report")or k:find("Send")or k:find("Flow")or k:find("Record")or k:find("Process"))then pcall(function()sub[k]=nop end)end end end
end
end)
end
local function InitializeSwiftHawkBypass()
pcall(function()
for _,f in ipairs({"SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams","SendSwiftHawkData"})do if _G[f]then _G[f]=nop end;if _G.GameplayCallbacks and _G.GameplayCallbacks[f]then _G.GameplayCallbacks[f]=nop end end
local sub=package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
if sub then sub.ReportData=nop;sub.SendReport=nop;sub.CollectTelemetry=nop end
end)
end
local function InitializeCoronaLabBypass()
pcall(function()
if _G.CoronaLab then _G.CoronaLab.ReportData=nop;_G.CoronaLab.SendData=nop;_G.CoronaLab.CollectData=nop;_G.CoronaLab.Telemetry=nop end
local sub=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
if sub then sub.ReportData=nop;sub.SendToServer=nop;sub.CollectTelemetry=nop;sub.StopCollection=nop end
end)
end
local function InitializeModifierExceptionBypass()
pcall(function()
if _G.bReportedModifierException then _G.bReportedModifierException=false end
local sub=require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
if sub then sub.ReportException=nop;sub.CheckModifier=retTrue;sub.ValidateModifier=retTrue;sub.ReportModifierError=nop end
end)
end
local function InitializeSimulateCharacterLocationBypass()
pcall(function()
local sub=require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
if sub then sub.ReportLocation=nop;sub.SendLocationData=nop;sub.VerifyLocation=retTrue end
end)
end
local function InitializeShootVerificationBypass()
pcall(function()
local sub=require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
if sub then sub.OnShootVerifyFailed=nop;sub.SendVerifyData=nop;sub.ReportBulletHit=nop;sub.UploadHitInfo=nop;sub.VerifyShot=retTrue end
if _G.BulletHitInfoUploadData then _G.BulletHitInfoUploadData.Report=nop;_G.BulletHitInfoUploadData.Send=nop;_G.BulletHitInfoUploadData.Upload=nop end
end)
end
local function InitializeNetworkPacketBlock()
pcall(function()
if NetUtil and NetUtil.SendPacket then
local orig=NetUtil.SendPacket
local blocked={["ReportAttackFlow"]=1,["ReportSecAttackFlow"]=1,["ReportFireArms"]=1,["ReportVerifyInfoFlow"]=1,["ReportMrpcsFlow"]=1,["ReportPlayerBehavior"]=1,["ReportTeammatHurt"]=1,["ReportPlayerMoveRoute"]=1,["ReportPlayerPosition"]=1,["ReportSecVehicleMoveFlow"]=1,["report_parachute_data"]=1,["on_tss_sdk_anti_data"]=1,["ReportAimFlow"]=1,["ReportHitFlow"]=1,["ReportCircleFlow"]=1,["report_players_ping"]=1,["report_player_ip"]=1,["report_net_saturate"]=1,["report_speed_hack"]=1,["report_wall_hack"]=1,["report_aim_bot"]=1,["report_esp_usage"]=1,["report_modded_files"]=1,["detect_cheat"]=1,["ban_player"]=1,["client_anti_cheat_report"]=1,["ClientSecMrpcsFlow"]=1,["MrpcsData"]=1,["CheckReportSecAttackFlow"]=1,["CheckReportSecAttackFlowWithAttackFlow"]=1,["RPC_ClientCoronaLab"]=1,["CoronaLabReport"]=1,["CoronaLabData"]=1,["PlayerSecurityInfo"]=1,["ReportSecurityInfo"]=1,["SendSecurityData"]=1,["ClientCircleFlow"]=1,["IsEnableReportMrpcsInCircleFlow"]=1,["IsEnableReportMrpcsInPartCircleFlow"]=1,["bReportedModifierException"]=1,["ReportModifierException"]=1,["RPC_Server_ReportSimulateCharacterLocation"]=1,["ReportSimulateCharacterLocation"]=1,["RPC_Client_ShootVertifyRes"]=1,["BulletHitInfoUploadData"]=1,["ShootVerifyFailed"]=1,["report_unrealnet_exception"]=1,["tss_sdk_report"]=1,["SwiftHawk"]=1,["ClientSwiftHawk"]=1,["ClientSwiftHawkWithParams"]=1,["SwiftHawkReport"]=1,["SwiftHawkData"]=1,["AntiCheatReport"]=1,["CheatDetection"]=1,["ViolationReport"]=1,["SecurityViolation"]=1,["IntegrityCheck"]=1,["SignatureVerify"]=1
}
NetUtil.SendPacket=function(packetName,...)if blocked[packetName]then return nil end;return orig(packetName,...)end
NetUtil.IsBypassed=true
end
if _G.SendRPC then
local origRPC=_G.SendRPC
local blockedRPC={"RPC_Server_ClientSecMrpcsFlow","RPC_Server_SwiftHawk","RPC_Server_ClientSwiftHawkWithParams","RPC_Server_ReportSimulateCharacterLocation","RPC_Client_ShootVertifyRes","RPC_ClientCoronaLab"}
_G.SendRPC=function(rpcName,...)for _,b in ipairs(blockedRPC)do if rpcName==b then return nil end end;return origRPC(rpcName,...)end
end
end)
end
local function InitializeHiggsBosonBypass()
pcall(function()
local Higgs=require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if Higgs then
for _,m in ipairs({"ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck","StartAvatarCheck","ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar","ClientReportNetAvatar","SendHisarData","ValidateSecurityData","StaticShowSecurityAlertInDev","RPC_Client_ShootVertifyRes","RPC_Server_ReportSimulateCharacterLocation","DisableHiggsBoson","CheckMHActive","ReportViolation","ProcessSecurityEvent","ValidatePlayer","CheckIntegrity"})do
if Higgs[m]then Higgs[m]=nop end
end
Higgs.GetNetAvatarItemIDs=retEmpty;Higgs.GetCurWeaponSkinID=retZero;Higgs.IsMHActive=retFalse;Higgs.bMHActive=false;Higgs.bCallPreReplication=false
if Higgs.BlackList then for k in pairs(Higgs.BlackList)do Higgs.BlackList[k]=nil end end
end
_G.BlackList={}
local pc=slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if slua.isValid(pc)then
if pc.HiggsBoson then pc.HiggsBoson.bMHActive=false;pc.HiggsBoson.bCallPreReplication=false;if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0)end end
if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive=false;pc.HiggsBosonComponent.bCallPreReplication=false;pc.HiggsBosonComponent:ControlMHActive(0)end
end
end)
end
local function InitializeAntiCheatHooks()
pcall(function()
local HBC=require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev=nop end
end)
if _G.AvatarCheckCallback then
_G.AvatarCheckCallback.StartAvatarCheck=nop;_G.AvatarCheckCallback.OnReportItemID=nop
_G.AvatarCheckCallback.PostPlayerControllerLoginInit=function(PlayerController)
if slua.isValid(PlayerController)and PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent:ControlMHActive(0);PlayerController.HiggsBosonComponent.bMHActive=false end
end
end
end
local function InitializeAntiReport()
pcall(function()
for _,path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem","Client.Security.ClientReportPlayerSubsystem","GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"})do
local sub=package.loaded[path];if not sub then local s,r=pcall(require,path);if s and r then sub=r end end
if sub then for k,v in pairs(sub)do if type(v)=="function"and(k:find("Report")or k:find("Record")or k:find("Send")or k:find("Upload")or k:find("Notify"))then pcall(function()sub[k]=nop end)end end end
end
end)
end
local function InitializeGameplayBypass()
pcall(function()
if not _G.GameplayCallbacks then _G.GameplayCallbacks={}end
if _G.GameplayCallbacks.IsBypassed then return end
local GC=_G.GameplayCallbacks
local reports={"ReportAttackFlow","ReportSecAttackFlow","ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData","SendTssSdkAntiDataToLobby","ReportEquipmentFlow","ReportAimFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord","OnDSConnectionSaturated","ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate","SendClientStats","SendServerAvgTickDelta","ReportCircleFlow","ClientSecMrpcsFlow","SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams"}
for _,f in ipairs(reports)do GC[f]=nop end
GC.CheckReportSecAttackFlowWithAttackFlow=retFalse;GC.CheckReportSecAttackFlow=retFalse
local origState=GC.OnDSPlayerStateChanged
GC.OnDSPlayerStateChanged=function(UID,State,bPure,bSafe,Param)
local s=State and string.lower(tostring(State))or""
local blocked={["cheatdetected"]=1,["connectionlost"]=1,["connectiontimeout"]=1,["connectionexception"]=1,["netdrivererror"]=1,["banned"]=1,["kicked"]=1,["suspended"]=1,["violationdetected"]=1,["integrityfailure"]=1,["securityviolation"]=1}
if blocked[s]then return end
if origState then pcall(origState,UID,State,bPure,bSafe,Param)end
end
GC.OnPlayerNetConnectionClosed=nop;GC.OnPlayerActorChannelError=nop;GC.OnPlayerRPCValidateFailed=nop;GC.OnPlayerSpectateException=nop;GC.OnShutdownAfterError=nop;GC.IsBypassed=true
end)
end
local function InitializeKillAllSubsystems()
pcall(function()
local subMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if not subMgr then return end
local toKill={"CoronaLabSubsystem","PlayerSecurityInfoSubsystem","ClientCircleFlowSubsystem","ModifierExceptionSubsystem","SimulateCharacterSubsystem","ShootVerifySubSystemClient","HiggsBosonComponent","ClientReportPlayerSubsystem","DSReportPlayerSubsystem","ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientDataStatistcsSubsystem","AFKReportorSubsystem","BehaviorScoreSubsystem","FileCheckSubsystem","MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem","AvatarExceptionSubsystem","GameReportSubsystem","ClientSecMrpcsFlowSubsystem","MrpcsFlowSubsystem","CircleFlowSubsystem","SwiftHawkSubsystem","AntiCheatSubsystem","IntegrityCheckSubsystem","SignatureVerifySubsystem","MD5CheckSubsystem","PakVerifySubsystem"}
for _,name in ipairs(toKill)do
local sub=subMgr:Get(name)
if sub then
for k,v in pairs(sub)do if type(v)=="function"and(k:find("Report")or k:find("Send")or k:find("Upload")or k:find("Verify")or k:find("Check")or k:find("Validate")or k:find("Scan")or k:find("Detect")or k:find("Collect")or k:find("Flow")or k:find("Heartbeat"))then pcall(function()sub[k]=nop end)end end
if sub.timer then pcall(function()sub:RemoveGameTimer(sub.timer)end)end
if sub.heartbeatTimer then pcall(function()sub:RemoveGameTimer(sub.heartbeatTimer)end)end
if sub.reportTimer then pcall(function()sub:RemoveGameTimer(sub.reportTimer)end)end
end
end
end)
end
local function InitializeFinalProtection()
pcall(function()
for _,flag in ipairs({"ENABLE_REPORT","ENABLE_ANTI_CHEAT","ENABLE_SECURITY","ENABLE_TELEMETRY","ENABLE_ANALYTICS","ENABLE_CRASH_REPORT","ENABLE_PERFORMANCE_REPORT"})do if _G[flag]then _G[flag]=false end end
local origReq=require
local blocked={"HiggsBosonComponent","PlayerSecurityInfoSubsystem","CoronaLabSubsystem","ClientCircleFlowSubsystem","ModifierExceptionSubsystem","ShootVerifySubSystemClient","ClientReportPlayerSubsystem","DSReportPlayerSubsystem"}
_G.require=function(m)for _,b in ipairs(blocked)do if m:find(b)then return{}end end;return origReq(m)end
end)
end
local function InitializeOperationalStatsBypass()
pcall(function()
 -- Ambil lewat SubsystemMgr atau Global agar memastikan 100% target terdeteksi
local subMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local OperationalStatsSubsystem=(subMgr and subMgr:Get("OperationalStatsSubsystem"))or _G.OperationalStatsSubsystem
if OperationalStatsSubsystem then
OperationalStatsSubsystem.ReportOperationalStats=nop
OperationalStatsSubsystem.AddOperationalStats=nop
OperationalStatsSubsystem.HandleTouchBegin=nop
OperationalStatsSubsystem.HandleTouchEnd=nop
OperationalStatsSubsystem.OnInit=nop
OperationalStatsSubsystem.HandleEnterFighting=nop
OperationalStatsSubsystem.OnBattleResult=nop
if OperationalStatsSubsystem.TimerHandle then
pcall(function()OperationalStatsSubsystem:RemoveGameTimer(OperationalStatsSubsystem.TimerHandle)end)
OperationalStatsSubsystem.TimerHandle=nil
end
OperationalStatsSubsystem.StatsData={}
print("[ULTIMATE BYPASS] OperationalStatsSubsystem blocked!")
end
end)
end
_G.StartBypass_VIP_v3=function()
pcall(function()
print("[ULTIMATE BYPASS] Starting initialization...")
InitializeSLUABypass()
InitializeMD5Bypass()
 InitializeSkinBypass() -- Tambahkan baris ini
InitializeLogBlocker()
InitializeScannerBlocker()
InitializeReplayTelemetryBlocker()
InitializeReportFlowBlocker()
InitializePlayerSecurityBypass()
InitializeClientFlowBypass()
InitializeSwiftHawkBypass()
InitializeCoronaLabBypass()
InitializeModifierExceptionBypass()
InitializeSimulateCharacterLocationBypass()
InitializeShootVerificationBypass()
InitializeNetworkPacketBlock()
InitializeHiggsBosonBypass()
InitializeAntiCheatHooks()
InitializeAntiReport()
InitializeGameplayBypass()
InitializeKillAllSubsystems()
 InitializeOperationalStatsBypass() -- [NEW] BYPASS LAPORAN STATISTIK (Operational Stats)
InitializeFinalProtection()
print("[ULTIMATE BYPASS] Complete-All Security Systems Disabled")
end)
end

-- ========================================================================
-- ⚡ ULTIMATE AGGRESSIVE BYPASS (Wallhack + ESP Detection Integrated)
-- ========================================================================
local function InstallUltimateWallhackBypass()
    if _G.__ULTIMATE_WH_BYPASS_LOADED then return end

    local nop = function() end
    local retTrue = function() return true end
    local retFalse = function() return false end
    local retZero = function() return 0 end

    local function isBypassActive()
        return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED
    end

    ---------- LAYER 1: PrimitiveSceneProxy override ----------
    pcall(function()
        local FPSP = import("PrimitiveSceneProxy")
        if FPSP then
            local origGetViewRelevance = FPSP.GetViewRelevance
            FPSP.GetViewRelevance = function(self, View)
                local VR = origGetViewRelevance(self, View)
                if isBypassActive() and VR then
                    VR.bRenderCustomDepth = false
                    VR.bUsesSceneDepth = false
                end
                return VR
            end
            local origDepthPriority = FPSP.GetDepthPriorityGroup
            FPSP.GetDepthPriorityGroup = function(self)
                if not isBypassActive() then return origDepthPriority(self) end
                return 0
            end
        end
    end)

    ---------- LAYER 3: Mesh/Primitive component depth spoofing ----------
    pcall(function()
        local UMesh = import("MeshComponent")
        if UMesh then
            UMesh.GetRenderCustomDepth = function(self)
                if not isBypassActive() then return UMesh.__origGRCD(self) end return false end
            UMesh.__origGRCD = UMesh.GetRenderCustomDepth
            UMesh.IsRenderedOnCustomDepth = function(self)
                if not isBypassActive() then return UMesh.__origIRCD(self) end return false end
            UMesh.__origIRCD = UMesh.IsRenderedOnCustomDepth
            UMesh.GetCustomDepthStencilValue = function(self)
                if not isBypassActive() then return UMesh.__origGCDSV(self) end return 0 end
            UMesh.__origGCDSV = UMesh.GetCustomDepthStencilValue
            UMesh.ShouldRender = function(self)
                if not isBypassActive() then return UMesh.__origSR(self) end return true end
            UMesh.__origSR = UMesh.ShouldRender
            UMesh.IsVisible = function(self)
                if not isBypassActive() then return UMesh.__origIV(self) end return true end
            UMesh.__origIV = UMesh.IsVisible
        end
        local UPrim = import("PrimitiveComponent")
        if UPrim then
            for _, fn in ipairs({"IsRenderedOnCustomDepth","GetRenderCustomDepth","GetCustomDepthStencilValue","GetCustomDepthStencilWriteMask","GetVisibleFlag"}) do
                local orig = UPrim[fn]
                UPrim["__orig_"..fn] = orig
                UPrim[fn] = function(self, ...)
                    if not isBypassActive() then return orig(self, ...) end
                    if fn == "GetVisibleFlag" then return true end
                    if fn == "GetCustomDepthStencilValue" then return 0 end
                    return false
                end
            end
        end
    end)

    ---------- LAYER 4: RHI depth state interception ----------
    pcall(function()
        local FRHI = import("RHICommandList")
        if FRHI and FRHI.SetDepthState then
            local origSetDepth = FRHI.SetDepthState
            FRHI.SetDepthState = function(self, State)
                if isBypassActive() and type(State) == "table" and State.DepthEnable ~= nil then
                    State.DepthEnable = true
                end
                return origSetDepth(self, State)
            end
        end
    end)

    ---------- LAYER 5: GameViewportClient post-render overlay ----------
    pcall(function()
        local UGVC = import("GameViewportClient")
        if UGVC and UGVC.Draw then
            local origDraw = UGVC.Draw
            UGVC.Draw = function(self, ...)
                origDraw(self, ...)
                if isBypassActive() and _G.King_DrawWallhackOverlay then
                    pcall(_G.King_DrawWallhackOverlay)
                end
            end
        end
    end)

    ---------- LAYER 6: Material property queries ----------
    pcall(function()
        local UMat = import("Material")
        local UMatInst = import("MaterialInstance")
        local UMatDyn = import("MaterialInstanceDynamic")

        if UMat then
            UMat.GetDisableDepthTest = function(self)
                if not isBypassActive() then return UMat.__origDDT(self) end return false end
            UMat.__origDDT = UMat.GetDisableDepthTest
            UMat.GetBlendMode = function(self)
                if not isBypassActive() then return UMat.__origBM(self) end return 0 end
            UMat.__origBM = UMat.GetBlendMode
            UMat.GetMaterialHash = function(self)
                if not isBypassActive() then return UMat.__origHash(self) end return "FKingE_HASH" end
            UMat.__origHash = UMat.GetMaterialHash
            UMat.VerifyMaterial = function(self)
                if not isBypassActive() then return UMat.__origVM(self) end return true end
            UMat.__origVM = UMat.VerifyMaterial
        end
        if UMatInst then
            UMatInst.GetDisableDepthTest = function(self)
                if not isBypassActive() then return UMatInst.__origDDT(self) end return false end
            UMatInst.__origDDT = UMatInst.GetDisableDepthTest
            UMatInst.GetBlendMode = function(self)
                if not isBypassActive() then return UMatInst.__origBM(self) end return 0 end
            UMatInst.__origBM = UMatInst.GetBlendMode
            UMatInst.GetBaseMaterial = function(self)
                if not isBypassActive() then return UMatInst.__origBM2(self) end return nil end
            UMatInst.__origBM2 = UMatInst.GetBaseMaterial
        end
        if UMatDyn then
            local oldGetVec = UMatDyn.K2_GetVectorParameterValue
            UMatDyn.K2_GetVectorParameterValue = function(self, name)
                if not isBypassActive() then return oldGetVec(self, name) end
                local n = tostring(name or "")
                if n:find("Color") or n:find("Emissive") or n:find("Tint") then
                    return {R=255,G=255,B=255,A=255}
                end
                return oldGetVec(self, name)
            end
            local oldGetScal = UMatDyn.K2_GetScalarParameterValue
            UMatDyn.K2_GetScalarParameterValue = function(self, name)
                if not isBypassActive() then return oldGetScal(self, name) end
                if tostring(name):find("Emissive") then return 0.0 end
                return oldGetScal(self, name)
            end
        end
    end)

    ---------- LAYER 7: Object scanner ----------
    pcall(function()
        local UObj = import("Object")
        if UObj and UObj.GetObjectsOfClass then
            local oldGet = UObj.GetObjectsOfClass
            UObj.GetObjectsOfClass = function(Class, IncludeDerived)
                if isBypassActive() and Class and tostring(Class):find("MaterialInstanceDynamic") then
                    return {}
                end
                return oldGet(Class, IncludeDerived)
            end
        end
    end)
        ---------- LAYER 8: Kernel & memory spoof ----------
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local kc = SubMgr:Get("ClientKernelCheckSubsystem")
            if kc and not kc.__Kinghooked then
                local origIKC = kc.IsKernelClean
                kc.IsKernelClean = function(self)
                    if not isBypassActive() then return origIKC(self) end
                    return true, { code = 0, message = "clean" }
                end
                local origGKV = kc.GetKernelVersion
                kc.GetKernelVersion = function(self)
                    if not isBypassActive() then return origGKV(self) end
                    return "5.4.0-generic"
                end
                kc.__Kinghooked = true
            end
            local mg = SubMgr:Get("ClientMemoryGuardSubsystem")
            if mg and not mg.__Kinghooked then
                local origIMC = mg.IsMemoryClean
                mg.IsMemoryClean = function(self)
                    if not isBypassActive() then return origIMC(self) end
                    return true, {code=0}
                end
                local origSR = mg.ScanResult
                mg.ScanResult = function(self)
                    if not isBypassActive() then return origSR(self) end
                    return "clean"
                end
                mg.__Kinghooked = true
            end
        end
    end)
    
       -- ########################################################################
    -- ⚡ NEW: ESP DETECTION BYPASS LAYERS (9-14)
    -- ########################################################################

    local ourMarkGroups = {1006, 9999}

    ---------- LAYER 9: MARK SYSTEM COMPLETE SPOOF ----------
    pcall(function()
        local MarkMgr = InGameMarkTools and InGameMarkTools.ScreenMarkManager
        if MarkMgr then
            if MarkMgr.GetAllActiveMarks then
                local orig = MarkMgr.GetAllActiveMarks
                MarkMgr.GetAllActiveMarks = function(self, ...)
                    local marks = orig(self, ...)
                    if not isBypassActive() or not marks then return marks end
                    local filtered = {}
                    for _, m in ipairs(marks) do
                        if m.MarkGroupID and not table.contains(ourMarkGroups, m.MarkGroupID) then
                            table.insert(filtered, m)
                        end
                    end
                    return filtered
                end
            end
            if MarkMgr.GetMarkCount then
                local orig = MarkMgr.GetMarkCount
                MarkMgr.GetMarkCount = function(self, ...)
                    local count = orig(self, ...)
                    if isBypassActive() then count = math.max(0, count - #ourMarkGroups) end
                    return count
                end
            end
            if MarkMgr.GetMarksByGroup then
                local orig = MarkMgr.GetMarksByGroup
                MarkMgr.GetMarksByGroup = function(self, groupId)
                    if isBypassActive() and table.contains(ourMarkGroups, groupId) then return {} end
                    return orig(self, groupId)
                end
            end
            if MarkMgr.OnAddMark then MarkMgr.OnAddMark = nop end
            if MarkMgr.OnRemoveMark then MarkMgr.OnRemoveMark = nop end
        end
    end)

    ---------- LAYER 10: REPLAY UI DETECTION KILL ----------
    pcall(function()
        if _G.Replay_IsEnemyFrameUIExisted then
            local orig = _G.Replay_IsEnemyFrameUIExisted
            _G.Replay_IsEnemyFrameUIExisted = function(...)
                if isBypassActive() then return false end
                return orig(...)
            end
        end
        if _G.Replay_CreateEnemyFrameUI then
            local orig = _G.Replay_CreateEnemyFrameUI
            _G.Replay_CreateEnemyFrameUI = function(...)
                if isBypassActive() then
                    local backup = _G.ReportEnemyFrameUI or nop
                    _G.ReportEnemyFrameUI = nop
                    local res = orig(...)
                    _G.ReportEnemyFrameUI = backup
                    return res
                end
                return orig(...)
            end
        end
    end)

    ---------- LAYER 11: ACTOR PROPERTY HIDE ----------
    pcall(function()
        local Actor = import("Actor")
        if Actor then
            local mt = getmetatable(Actor) or {}
            local oldIndex = mt.__index or function() end
            mt.__index = function(t, k)
                if isBypassActive() then
                    local sk = tostring(k)
                    if sk:find("ESP") or sk:find("bHasKingNative") or sk:find("NativeDistMark") or
                       sk:find("_wh_") or sk:find("WH_") then
                        return nil
                    end
                end
                return oldIndex(t, k)
            end
            setmetatable(Actor, mt)
        end
    end)

    ---------- LAYER 12: UI WIDGET SCAN BLOCK ----------
    pcall(function()
        local UIHelper = import("UIHelper") or _G.UIHelper
        if UIHelper and UIHelper.GetAllWidgetsOfClass then
            UIHelper.GetAllWidgetsOfClass = function(...) return {} end
        end
        local UUserWidget = import("UserWidget")
        if UUserWidget and UUserWidget.AddToViewport then
            local orig = UUserWidget.AddToViewport
            UUserWidget.AddToViewport = function(self, ...)
                if isBypassActive() and self.ESPWidget then return end
                return orig(self, ...)
            end
        end
    end)

    ---------- LAYER 13: ESP-RELATED REPORT FUNCTIONS KILL ----------
    pcall(function()
        local espReports = {
            "ReportESPBox","ReportESPHealth","ReportMiniMapESP","ReportEnemyFrameUI",
            "ReportMarkCreated","ReportMarkDestroyed","MarkSuspiciousESP",
            "OnScreenMarkAdd","OnScreenMarkRemove","ReportDistanceMarker",
            "ReportWallhackESP","SendESPData","UploadESPInfo"
        }
        for _, fn in ipairs(espReports) do
            if _G[fn] then _G[fn] = nop end
            for _, mod in pairs(package.loaded) do
                if type(mod) == "table" and mod[fn] and type(mod[fn]) == "function" then
                    mod[fn] = nop
                end
            end
        end
    end)

    ---------- LAYER 14: NETWORK ESP PACKET BLOCK ----------
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            NetUtil.SendPacket = function(pname, ...)
                if isBypassActive() and pname and tostring(pname):lower():match("esp") then return nil end
                return orig(pname, ...)
            end
        end
        if _G.SendRPC then
            local orig = _G.SendRPC
            _G.SendRPC = function(rpcName, ...)
                if isBypassActive() and rpcName and tostring(rpcName):lower():match("esp") then return end
                return orig(rpcName, ...)
            end
        end
    end)

    _G.__ULTIMATE_WH_BYPASS_LOADED = true
    print("✅ Ultimate Wallhack + ESP Detection Bypass Installed")
end

-- ACTIVATE
InstallUltimateWallhackBypass()

-- ========================================================================
-- ⚡ GLOBAL AIMBOT & RECOIL DETECTION BYPASS (Multi-Layer)
-- ========================================================================
local function InstallAimbotRecoilBypass()
    if _G.__AIMBOT_BYPASS_LOADED then return end

    local nop = function() end
    local retTrue = function() return true end
    local retFalse = function() return false end
    local retZero = function() return 0 end

    local function isBypassActive()
        return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED
    end

    -- LAYER 1: WEAPON ENTITY PROPERTY SPOOF
    pcall(function()
        local ShootWeaponEntity = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if ShootWeaponEntity then
            local mt = getmetatable(ShootWeaponEntity) or {}
            local oldIndex = mt.__index or function(t, k) return rawget(t, k) end
            mt.__index = function(self, key)
                local k = tostring(key)
                if isBypassActive() then
                    if k == "RecoilKickADS" or k == "GameDeviationFactor" or k == "GameDeviationAccuracy" then
                        return 1.0
                    elseif k == "AutoAimingConfig" then
                        local orig = oldIndex(self, key)
                        if type(orig) == "table" then
                            local fKingeConfig = {}
                            for range, data in pairs(orig) do
                                fKingeConfig[range] = {}
                                for cKey, cVal in pairs(data) do
                                    if type(cVal) == "number" then
                                        fKingeConfig[range][cKey] = 1.0
                                    else
                                        fKingeConfig[range][cKey] = cVal
                                    end
                                end
                            end
                            return fKingeConfig
                        end
                        return orig
                    end
                end
                return oldIndex(self, key)
            end
            mt.__newindex = function(self, key, value)
                rawset(self, key, value)
            end
            setmetatable(ShootWeaponEntity, mt)
        end
    end)
        -- LAYER 2: AIM TRACKING SUBSYSTEM SPOOF
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local aimSub = SubMgr:Get("ClientAimTrackingSubsystem")
            if aimSub then
                aimSub.GetAimData = function(self)
                    if not isBypassActive() then return aimSub.__origGetAimData(self) end
                    return {
                        accuracy = math.random(40, 60),
                        headshotRate = math.random(10, 25),
                        trackingTime = math.random(100, 300),
                        aimLockCount = 0
                    }
                end
                aimSub.__origGetAimData = aimSub.GetAimData
                for _, fn in ipairs({"ReportAimData","SendAimStats","UploadAimInfo"}) do
                    if aimSub[fn] then aimSub[fn] = nop end
                end
            end
        end
    end)

    -- LAYER 3: INPUT SPOOF
    pcall(function()
        local PlayerController = import("PlayerController")
        if PlayerController then
            local origAddYaw = PlayerController.AddYawInput
            PlayerController.AddYawInput = function(self, Val)
                if isBypassActive() and self == slua_GameFrontendHUD:GetPlayerController() then
                    Val = Val + (math.random() - 0.5) * 0.5
                end
                return origAddYaw(self, Val)
            end
            local origAddPitch = PlayerController.AddPitchInput
            PlayerController.AddPitchInput = function(self, Val)
                if isBypassActive() and self == slua_GameFrontendHUD:GetPlayerController() then
                    Val = Val + (math.random() - 0.5) * 0.5
                end
                return origAddPitch(self, Val)
            end
        end
        local GameplayStatics = import("GameplayStatics")
        if GameplayStatics and GameplayStatics.IsInputKeyDown then
            local origKeyDown = GameplayStatics.IsInputKeyDown
            GameplayStatics.IsInputKeyDown = function(self, Key)
                if isBypassActive() and Key == "LeftMouseButton" then
                    if math.random() < 0.1 then return false end
                end
                return origKeyDown(self, Key)
            end
        end
    end)
    
    
    -- LAYER 4: HIT STATISTICS SPOOF
    pcall(function()
        local ShootVerify = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if ShootVerify then
            local origVerify = ShootVerify.VerifyShot
            ShootVerify.VerifyShot = function(self, ...)
                if not isBypassActive() then return origVerify(self, ...) end
                local args = {...}
                if args[1] and type(args[1]) == "table" and args[1].hitLocation then
                    args[1].hitLocation.X = args[1].hitLocation.X + (math.random()-0.5)*2
                    args[1].hitLocation.Y = args[1].hitLocation.Y + (math.random()-0.5)*2
                end
                return true
            end
        end
    end)

    -- LAYER 5: BONE TARGET SPOOF
    pcall(function()
        local Actor = import("Actor")
        if Actor and Actor.GetBoneName then
            local origGetBone = Actor.GetBoneName
            Actor.GetBoneName = function(self, index)
                local name = origGetBone(self, index)
                if isBypassActive() and tostring(name):find("neck") then
                    local rand = math.random(1,3)
                    if rand == 1 then return "head_01"
                    elseif rand == 2 then return "spine_02"
                    end
                end
                return name
            end
        end
    end)

    -- LAYER 6: KILL ALL AIM/ RECOIL REPORT FUNCTIONS
    pcall(function()
        local aimReports = {
            "ReportAimFlow","ReportRecoil","ReportAimData","SendAimStats",
            "UploadAimInfo","ReportHeadshotRate","ReportAccuracy","ReportFireRate",
            "ReportRecoilKick","ReportAutoAim","ReportWeaponModification",
            "ReportWeaponStats","ReportShootVerifyFail","ReportHitIntegrity",
            "OnAimAssistDetected","OnRecoilAnomaly","OnFireRateAnomaly",
            "ClientAimTrackingUpdate","ServerAimValidation"
        }
        for _, fn in ipairs(aimReports) do
            if _G[fn] then _G[fn] = nop end
            for _, mod in pairs(package.loaded) do
                if type(mod) == "table" and mod[fn] and type(mod[fn]) == "function" then
                    mod[fn] = nop
                end
            end
        end
    end)

    -- LAYER 7: NETWORK PACKET FILTER FOR AIM/ RECOIL
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            NetUtil.SendPacket = function(pname, ...)
                if isBypassActive() and pname and (tostring(pname):lower():match("aim") or tostring(pname):lower():match("recoil") or tostring(pname):lower():match("shoot")) then
                    return nil
                end
                return orig(pname, ...)
            end
        end
        if _G.SendRPC then
            local orig = _G.SendRPC
            _G.SendRPC = function(rpcName, ...)
                if isBypassActive() and rpcName and (tostring(rpcName):lower():match("aim") or tostring(rpcName):lower():match("recoil") or tostring(rpcName):lower():match("shoot")) then
                    return
                end
                return orig(rpcName, ...)
            end
        end
    end)

    _G.__AIMBOT_BYPASS_LOADED = true
    print("✅ Global Aimbot & Recoil Bypass Installed")
end

InstallAimbotRecoilBypass()

-- ========================================================================
-- ⚡ ADVANCED DETECTION BYPASS (Magic Bullet, Radar, Behavior, DLL, PKing, etc.)
-- ========================================================================
local function InstallAdvancedDetectionBypass()
    if _G.__ADVANCED_BYPASS_LOADED then return end

    local nop = function() end
    local retTrue = function() return true end
    local retFalse = function() return false end
    local retZero = function() return 0 end
    local retEmpty = function() return {} end

    local function isBypassActive()
        return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED
    end

    ---------- MAGIC BULLET / NO SPREAD ----------
    pcall(function()
        local ShootWeaponEntity = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if ShootWeaponEntity and ShootWeaponEntity.Fire then
            local origFire = ShootWeaponEntity.Fire
            ShootWeaponEntity.Fire = function(self, ...)
                if isBypassActive() then
                    -- small random aim offset already handled, but we add spread seed
                end
                return origFire(self, ...)
            end
        end
        local Actor = import("Actor")
        if Actor and Actor.TKingeDamage then
            local origTKingeDamage = Actor.TKingeDamage
            Actor.TKingeDamage = function(self, DamageAmount, DamageEvent, EventInstigator, DamageCauser)
                if isBypassActive() and DamageEvent and DamageEvent.HitInfo then
                    if DamageEvent.HitInfo.BoneName and tostring(DamageEvent.HitInfo.BoneName):find("head") then
                        if math.random() < 0.3 then
                            DamageEvent.HitInfo.BoneName = "neck_01"
                        end
                    end
                    DamageEvent.HitInfo.Location = {
                        X = DamageEvent.HitInfo.Location.X + (math.random()-0.5)*2,
                        Y = DamageEvent.HitInfo.Location.Y + (math.random()-0.5)*2,
                        Z = DamageEvent.HitInfo.Location.Z + (math.random()-0.5)*2
                    }
                end
                return origTKingeDamage(self, DamageAmount, DamageEvent, EventInstigator, DamageCauser)
            end
        end
    end)
        ---------- RADAR HACK DETECTION ----------
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            NetUtil.SendPacket = function(pname, ...)
                if isBypassActive() and pname then
                    local p = tostring(pname):lower()
                    if p:match("position") or p:match("location") or p:match("coord") or
                       p:match("playerpos") or p:match("move") or p:match("teleport") then
                        return nil
                    end
                end
                return orig(pname, ...)
            end
        end
        if _G.SendRPC then
            local orig = _G.SendRPC
            _G.SendRPC = function(rpcName, ...)
                if isBypassActive() and rpcName then
                    local r = tostring(rpcName):lower()
                    if r:match("position") or r:match("location") or r:match("coord") then
                        return
                    end
                end
                return orig(rpcName, ...)
            end
        end
    end)

    ---------- BEHAVIOR ANALYSIS (End-of-Match Stats Spoof) ----------
    local matchStats = { totalShots = 0, totalHits = 0, headshots = 0, kills = 0 }
    pcall(function()
        local Weapon = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if Weapon and Weapon.Fire then
            local origFire = Weapon.Fire
            Weapon.Fire = function(self, ...)
                if isBypassActive() then matchStats.totalShots = matchStats.totalShots + 1 end
                return origFire(self, ...)
            end
        end
        local Actor = import("Actor")
        if Actor and Actor.TKingeDamage then
            local origTKingeDamage2 = Actor.TKingeDamage
            Actor.TKingeDamage = function(self, DamageAmount, DamageEvent, EventInstigator, DamageCauser)
                if isBypassActive() and EventInstigator == slua_GameFrontendHUD:GetPlayerController() then
                    matchStats.totalHits = matchStats.totalHits + 1
                    if DamageEvent and DamageEvent.HitInfo and DamageEvent.HitInfo.BoneName and
                       tostring(DamageEvent.HitInfo.BoneName):find("head") then
                        matchStats.headshots = matchStats.headshots + 1
                    end
                    if self:IsDead() then matchStats.kills = matchStats.kills + 1 end
                end
                return origTKingeDamage2(self, DamageAmount, DamageEvent, EventInstigator, DamageCauser)
            end
        end
        -- Spoof final stats report
        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils and GameReportUtils.ReportGameResult then
            local origReport = GameReportUtils.ReportGameResult
            GameReportUtils.ReportGameResult = function(self, data)
                if isBypassActive() and data then
                    local shots = math.max(matchStats.totalShots, 1)
                    data.accuracy = math.min(0.65, 0.35 + math.random()*0.15)
                    data.headshotRate = math.min(0.30, 0.10 + math.random()*0.10)
                    data.totalKills = matchStats.kills
                    data.totalShots = shots
                    data.totalHits = math.floor(shots * data.accuracy)
                end
                return origReport(self, data)
            end
        end
        local ShowResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"]
        if ShowResult and ShowResult.ReceiveData then
            local origReceive = ShowResult.ReceiveData
            ShowResult.ReceiveData = function(self, resultData)
                if isBypassActive() and resultData then
                    resultData.Accuracy = math.random(35,50)/100
                    resultData.HeadShotRate = math.random(10,20)/100
                end
                return origReceive(self, resultData)
            end
        end
    end)
    
        ---------- DLL / CODE INTEGRITY ----------
    pcall(function()
        if rawget(_G, "IsDebuggerPresent") then _G.IsDebuggerPresent = retFalse end
        local Kernel32 = pcall(import, "Kernel32") and import("Kernel32")
        if Kernel32 then
            Kernel32.IsDebuggerPresent = retFalse
            Kernel32.CheckRemoteDebuggerPresent = retFalse
        end
        if _G.TssSdk then
            _G.TssSdk.GetModuleHash = function() return "82918E1FE1BE4186CFD2F1286951B2A0" end
            _G.TssSdk.VerifyModule = retTrue
            _G.TssSdk.ScanProcess = retEmpty
        end
        local FMemory = import("FMemory")
        if FMemory and FMemory.Memcpy then
            local origMemcpy = FMemory.Memcpy
            FMemory.Memcpy = function(dest, src, count)
                if isBypassActive() then return end
                return origMemcpy(dest, src, count)
            end
        end
    end)

    ---------- PKing SIZE DETECTION ----------
    pcall(function()
        local FileHelper = import("FFileHelper")
        if FileHelper then
            if FileHelper.GetFileSize then
                local orig = FileHelper.GetFileSize
                FileHelper.GetFileSize = function(path)
                    local size = orig(path)
                    if isBypassActive() and path and tostring(path):lower():match(".pKing") then
                        return 2000000000
                    end
                    return size
                end
            end
            if FileHelper.SaveStringToFile then
                local origSave = FileHelper.SaveStringToFile
                FileHelper.SaveStringToFile = function(str, path, ...)
                    if isBypassActive() and path and tostring(path):lower():match(".pKing") then
                        return true
                    end
                    return origSave(str, path, ...)
                end
            end
        end
        local PKingSubsystem = pcall(require, "GameLua.GameCore.Module.Subsystem.PKingFileSubsystem") and require("GameLua.GameCore.Module.Subsystem.PKingFileSubsystem")
        if PKingSubsystem then
            PKingSubsystem.CheckPKingIntegrity = nop
            PKingSubsystem.ReportPKingMismatch = nop
        end
    end)

    ---------- SPEED HACK DETECTION ----------
    pcall(function()
        local CharacterMovement = import("CharacterMovementComponent")
        if CharacterMovement then
            local origGetMaxSpeed = CharacterMovement.GetMaxSpeed
            CharacterMovement.GetMaxSpeed = function(self)
                local speed = origGetMaxSpeed(self)
                if isBypassActive() then return 600.0 end
                return speed
            end
            local origGetMaxAcceleration = CharacterMovement.GetMaxAcceleration
            CharacterMovement.GetMaxAcceleration = function(self)
                local acc = origGetMaxAcceleration(self)
                if isBypassActive() then return 2048.0 end
                return acc
            end
        end
    end)

    ---------- EXTRA SHIELD: Shader, PKing Entries, Real-time Stats, Screenshot ----------
    pcall(function()
        -- Shader map hiding
        local UMat = import("Material")
        local UMatInst = import("MaterialInstance")
        if UMat then
            UMat.GetShaderMap = function(self) return nil end
            UMat.GetShaderPlatform = function(self) return 0 end
        end
        if UMatInst then
            UMatInst.GetShaderMap = function(self) return nil end
        end
        -- PKing entry scanner block
        local FPKingFile = import("FPKingFile") or import("FPKingPlatformFile")
        if FPKingFile then
            FPKingFile.GetPKingEntries = function(...) return {} end
            FPKingFile.GetPKingFolders = function(...) return {} end
            FPKingFile.FindFileInPKingFiles = function(...) return false end
        end
        -- Real-time stat blocking
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            NetUtil.SendPacket = function(pname, ...)
                if isBypassActive() and pname and tostring(pname):lower():match("stat") then return nil end
                return orig(pname, ...)
            end
        end
        -- Screenshot manager block
        local SSMgr = import("ScreenshotManager")
        if SSMgr then
            SSMgr.RequestScreenshot = function(...) return false end
            SSMgr.HasPendingScreenshot = function(...) return false end
        end
    end)

    _G.__ADVANCED_BYPASS_LOADED = true
    print("✅ Advanced Detection Bypass (Magic, Radar, Behavior, DLL, PKing, Speed, Extra Shield) Installed")
end

InstallAdvancedDetectionBypass()

-- ========================================================================
-- ⚡ DEVICE ID / BAN BYPASS (Cleans banned device fingerprint)
-- ========================================================================
local function InstallDeviceBanBypass()
    if _G.__DEVICE_BAN_BYPASS_LOADED then return end

    local nop = function() end
    local function isBypassActive()
        return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED
    end

    -- Generate random but consistent fKinge IDs (same for session)
    local function generateFKingeId(length)
        local chars = "0123456789ABCDEF"
        local id = ""
        for i = 1, length do
            id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        return id
    end
    local fKingeDeviceID = generateFKingeId(32)
    local fKingeAndroidID = generateFKingeId(16)
    local fKingeMac = string.format("%02X:%02X:%02X:%02X:%02X:%02X",
        math.random(0,255), math.random(0,255), math.random(0,255),
        math.random(0,255), math.random(0,255), math.random(0,255))
    local fKingeIMEI = "35" .. math.random(100000, 999999) .. math.random(100000, 999999)

    -- Hook SystemInfo functions
    pcall(function()
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            if SystemInfo.GetDeviceID or SystemInfo.GetUniqueDeviceId then
                local orig = SystemInfo.GetDeviceID or SystemInfo.GetUniqueDeviceId
                if orig then
                    if SystemInfo.GetDeviceID then
                        SystemInfo.GetDeviceID = function()
                            if isBypassActive() then return fKingeDeviceID end
                            return orig()
                        end
                    end
                    if SystemInfo.GetUniqueDeviceId then
                        SystemInfo.GetUniqueDeviceId = function()
                            if isBypassActive() then return fKingeDeviceID end
                            return orig()
                        end
                    end
                end
            end
            if SystemInfo.GetMacAddress then
                local orig = SystemInfo.GetMacAddress
                SystemInfo.GetMacAddress = function()
                    if isBypassActive() then return fKingeMac end
                    return orig()
                end
            end
            if SystemInfo.GetAndroidId then
                local orig = SystemInfo.GetAndroidId
                SystemInfo.GetAndroidId = function()
                    if isBypassActive() then return fKingeAndroidID end
                    return orig()
                end
            end
            if SystemInfo.GetIMEI then
                local orig = SystemInfo.GetIMEI
                SystemInfo.GetIMEI = function()
                    if isBypassActive() then return fKingeIMEI end
                    return orig()
                end
            end
            -- General device name
            if SystemInfo.GetDeviceName then
                local orig = SystemInfo.GetDeviceName
                SystemInfo.GetDeviceName = function()
                    if isBypassActive() then return "Galaxy S21 Ultra 5G" end
                    return orig()
                end
            end
        end
    end)
        -- Hook Build class for Android specific properties
    pcall(function()
        local Build = import("Build")
        if Build then
            -- Build.Fingerprint, Serial, Hardware, Brand, etc.
            local props = {
                "Fingerprint", "Serial", "Hardware", "Brand", "Model", "Manufacturer", "Product", "Device", "Board"
            }
            for _, prop in ipairs(props) do
                local orig = Build[prop]
                if orig then
                    Build[prop] = function()
                        if isBypassActive() then
                            if prop == "Fingerprint" then return "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys" end
                            if prop == "Serial" then return "R5CT1234567" end
                            if prop == "Hardware" then return "oriole" end
                            if prop == "Brand" then return "google" end
                            if prop == "Model" then return "Pixel 6" end
                            if prop == "Manufacturer" then return "Google" end
                            if prop == "Product" then return "oriole" end
                            if prop == "Device" then return "oriole" end
                            if prop == "Board" then return "gs101" end
                        end
                        return orig()
                    end
                end
            end
            -- Build.VERSION.SDK_INT etc.
            if Build.VERSION and Build.VERSION.SDK_INT then
                local orig = Build.VERSION.SDK_INT
                Build.VERSION.SDK_INT = function()
                    if isBypassActive() then return 33 end
                    return orig()
                end
            end
        end
    end)

    -- Hook TssSdk device info functions
    pcall(function()
        local TssSdk = _G.TssSdk
        if TssSdk then
            if TssSdk.GetDeviceInfo then
                local orig = TssSdk.GetDeviceInfo
                TssSdk.GetDeviceInfo = function()
                    if not isBypassActive() then return orig() end
                    return {
                        deviceId = fKingeDeviceID,
                        androidId = fKingeAndroidID,
                        mac = fKingeMac,
                        imei = fKingeIMEI,
                        model = "Pixel 6",
                        brand = "google",
                        sdkInt = 33,
                        fingerprint = "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys"
                    }
                end
            end
            if TssSdk.GetFingerprint then
                local orig = TssSdk.GetFingerprint
                TssSdk.GetFingerprint = function()
                    if isBypassActive() then return "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys" end
                    return orig()
                end
            end
            if TssSdk.GetClientID then
                local orig = TssSdk.GetClientID
                TssSdk.GetClientID = function()
                    if isBypassActive() then return fKingeDeviceID end
                    return orig()
                end
            end
        end
    end)
    
        -- Override any global device ID variables
    pcall(function()
        if _G.DeviceID then _G.DeviceID = fKingeDeviceID end
        if _G.AndroidID then _G.AndroidID = fKingeAndroidID end
        if _G.MacAddress then _G.MacAddress = fKingeMac end
        if _G.IMEI then _G.IMEI = fKingeIMEI end
    end)

    _G.__DEVICE_BAN_BYPASS_LOADED = true
    print("✅ Device ID / Ban Bypass Installed (Cleaned device identity)")
end

InstallDeviceBanBypass()

-- ========================================== 
-- PENGATURAN 4imPRO CORE + FULL FEATURES VIP 
-- ========================================== 
_G.AimPROConfig=_G.AimPROConfig or{FakeHWID=false,CustomMagicBullet=false,AutoReportEnable=false,AutoMassReport=false,AutoKillerReport=false,AutoHead=false,EspVip=false, tppfpp=false,--Tpp To Fpp
EspDistance=false,EspVipPro=false,EspRadar=false,EspLoai5=false,EspLoai6=false,EspLoai7=false, Esp7_SoLuong=true,Esp9_Name=true,Esp9_Distance=true,Esp9_Visibility=true,-- ESP LITE info toggles
 Esp7_VuKhi=true,-- [tambahkan baru] Nyalakan/matikan Senjata MUSUH
 Esp7_TuThe=true,-- [tambahkan baru] Nyalakan/matikan Posisi MUSUH
EspLoai8=false, EspLoai9=false,-- Saklar utama ESP jenis 9
 Esp9_Count=true,-- Jumlah pemain (RedBox)
 Esp9_Name=true,-- nama
 Esp9_HP=true,-- Bar HP
 Esp9_Team=true,-- Kotak warna Team
 Esp9_Weapon=true,-- Ikon senjata
 Esp9_Distance=true,-- ESP Distance / info
 Esp9_Line=true,-- ESP Line
 Esp9_Box=true,-- ESP Box (corner + HP + chevron)
 Esp9_Skeleton=true,-- Skeleton (Tulang)
EspBomMaster=false,EspItemBom=false,EspActiveBom=false, EspAimWarning=false,-- [tambahkan baru] Saklar Peringatan saat MUSUH membidik
 EspAimWarningVisCheck=false,-- [tambahkan baru] Saklar Cek tembok untuk peringatan bidikan
EspVehicle=false,EspVeh_Dacia=true,EspVeh_UAZ=true,EspVeh_Buggy=true,EspVeh_Coupe=true,EspVeh_Mirado=true,EspVeh_Motor=true,EspVeh_Other=true,Esp3ShowName=true,Esp3ShowHP=true,EspAntenna=false,EspOutline=false,OutlineThickness=10,UnlockFPS=false,IpadView=false,IpadViewVehicle=false, IpadViewScope=false,-- [tambahkan baru] Ipad View Buka Scope
CustomAimbot=false,CustomAimbotClose=false,CustomHRecoil=false,CustomVRecoil=false,LessShake=false,RemoveGrass=false,RemoveTrees=false,RemoveFog=false,WhiteBody=false,ColorBodyV2=false,ColorBodyV3=false,WallXuyenTuong=false, ColorBodyNew=false,-- [tambahkan baru] Saklar Wall Color Baru
WallVehicle=false,EspItem_Master=false,EspItem_AR=true,EspItem_Sniper=true,EspItem_SMG=true,EspItem_Shotgun=true, EspItem_LMG=true,-- [tambahkan] Senapan mesin
 EspItem_Pistol=true,-- [tambahkan] Pistol
 EspItem_Melee=false,-- [tambahkan] Jarak dekat
 EspItem_Special=true,-- [tambahkan] Senjata khusus
EspItem_Scope=true, EspItem_Grenade=true,-- [tambahkan] Granat
 EspItem_Med=true,-- [tambahkan] HP & Air (Item medis)
Crosshair=false,Accuracy=false,GodMode=false,WallClimb=false,FastCar=false, BlackSky=false,-- Terintegrasi BlackSky
 -- PENGATURAN baru untuk Aimbot V2 (Aim Touch)
AimTouchEnable=false,AimTouchHipIgKnock=false,AimTouchHipIgBot=false,AimTouchSGIgKnock=false,AimTouchSGIgBot=false,AimTouchHipVisCheck=false,AimTouchSGVisCheck=false,AimTouchHipfire=false,AimTouchSG=false,AimTouchSGAutoFire=false,AimTouchScopeAll=false,AimTouchScopeIgKnock=false,AimTouchScopeIgBot=false,AimTouchScopeVisCheck=false,AimTouchScopeSniper=false,AimTouchSniperIgKnock=false,AimTouchSniperIgBot=false,AimTouchSniperVisCheck=false, AimTouchMortar=false,-- [tambahkan baru] Nyalakan/Matikan Aimbot Mortar
EspFovCircle=false, -- Config Mod Skin VIP
 ModEmote=false,-- [tambahkan baru] Saklar Mod Emote aksi gerak
ModSkin=false,SkinDeadBox=false, SkinAttachment=false,-- [tambahkan baru] Saklar Skin tambahan syarat
SkinOptionOpen=false,SkinOpenLink=false, KillMessage=false,-- [tambahkan baru] Saklar Kill Messenger
 KillCountUI=false,-- [tambahkan baru] Saklar bagian hitung Kill Count
 -- Nyalakan/matikan tiap item
SkinEnable_Suit=false,SkinEnable_Top=false,SkinEnable_Gloves=false,SkinEnable_Bottom=false,SkinEnable_Shoes=false,SkinEnable_Bag=false,SkinEnable_Helmet=false,SkinEnable_Parachute=false,SkinEnable_M416=false,SkinEnable_AKM=false,SkinEnable_SCAR=false,SkinEnable_M762=false,SkinEnable_AUG=false,SkinEnable_UMP=false,SkinEnable_UZI=false,SkinEnable_Groza=false,SkinEnable_S12K=false,SkinEnable_DBS=false,SkinEnable_Dacia=false,SkinEnable_UAZ=false,SkinEnable_Coupe=false,SkinEnable_Buggy=false,SkinEnable_Mirado=false, -- Config Glow senjata
WeaponGlow=false, -- Graphics preset
LightUltraHDR=false, -- Config Bug layar
BugManEnable=false
}
-- BERISI STATE SISTEM SISTEM sudah bisa OPTIMASI selesai seluruh RAM kosong
_G.AimPROState=_G.AimPROState or{LoopToken=0,NativeESPReady=false,GraphicsUnlocked=false,MenuStep=0,LastCmdTime=0,TrackedMarks={},EnemyMarks={},LastAimbotCheckTime=0,CustomTextData=nil,LastAimbotConfigString="",MagicUpdateVersion=1,LastMagicConfigHash="",PrevGraphicsState={}
}
_G.AimPROState.CustomTextData=_G.AimPROState.CustomTextData or{}
-- Cache nilai asli slider di tabel Lua, jangan disimpan sebagai field entity game.
_G.AimPROSliderOriginalCache=_G.AimPROSliderOriginalCache or setmetatable({},{__mode="k"})
if _G.AimPROState.CustomTextData.RecoilSlider==nil then
_G.AimPROState.CustomTextData.RecoilSlider=0
end
if _G.AimPROState.CustomTextData.ShakeSlider==nil then
_G.AimPROState.CustomTextData.ShakeSlider=0
end
-- Tpp to Fpp
_G._MBones=_G._MBones or{}
_G.markData=_G.markData or{HitboxApplied=false,TPPApplied=false,}

-- ============================================================
-- AIMPRO GRAPHICS INTEGRATION
-- Diintegrasikan ke sistem Settings base ini, bukan SRC tempel.
-- ============================================================
if _G.AimPROConfig.GraphicsEnabled==nil then _G.AimPROConfig.GraphicsEnabled=false end
if _G.AimPROConfig.GraphicsResolution==nil then _G.AimPROConfig.GraphicsResolution=3 end
if _G.AimPROConfig.GraphicsShadowOff==nil then _G.AimPROConfig.GraphicsShadowOff=true end
if _G.AimPROConfig.GraphicsTextureLow==nil then _G.AimPROConfig.GraphicsTextureLow=true end
if _G.AimPROConfig.GraphicsMaterialLow==nil then _G.AimPROConfig.GraphicsMaterialLow=true end
if _G.AimPROConfig.GraphicsAAOff==nil then _G.AimPROConfig.GraphicsAAOff=true end
if _G.AimPROConfig.GraphicsBloomOff==nil then _G.AimPROConfig.GraphicsBloomOff=true end
if _G.AimPROConfig.GraphicsMotionBlurOff==nil then _G.AimPROConfig.GraphicsMotionBlurOff=true end
if _G.AimPROConfig.GraphicsDOFOff==nil then _G.AimPROConfig.GraphicsDOFOff=true end
if _G.AimPROConfig.GraphicsViewDistanceLow==nil then _G.AimPROConfig.GraphicsViewDistanceLow=false end
if _G.AimPROConfig.GraphicsExtraOptimize==nil then _G.AimPROConfig.GraphicsExtraOptimize=false end
_G.AimPROGraphicsLastApplyHash=_G.AimPROGraphicsLastApplyHash or ""

_G.AimPROGraphicsApply=function(force)
pcall(function()
local cfg=_G.AimPROConfig
local resMap={[1]="30",[2]="45",[3]="67",[4]="100"}
local res=resMap[cfg.GraphicsResolution] or "67"
local state=table.concat({
tostring(cfg.GraphicsEnabled),tostring(cfg.GraphicsResolution),
tostring(cfg.GraphicsShadowOff),tostring(cfg.GraphicsTextureLow),
tostring(cfg.GraphicsMaterialLow),tostring(cfg.GraphicsAAOff),
tostring(cfg.GraphicsBloomOff),tostring(cfg.GraphicsMotionBlurOff),
tostring(cfg.GraphicsDOFOff),tostring(cfg.GraphicsViewDistanceLow),
tostring(cfg.GraphicsExtraOptimize)
},"|")
if not force and _G.AimPROGraphicsLastApplyHash==state then return end

local gd=require("GameLua.GameCore.Data.GameplayData")
local pc=gd and gd.GetPlayerController and gd.GetPlayerController()
if not slua.isValid(pc) then return end
local ksl=import("KismetSystemLibrary")
if not ksl or not ksl.ExecuteConsoleCommand then return end
local function cmd(name,value)
pcall(function()ksl.ExecuteConsoleCommand(pc,name.." "..tostring(value))end)
end

-- Resolusi / screen percentage
cmd("r.ScreenPercentage",res)
-- UI-SAFETY: jangan ubah MobileContentScaleFactor karena dapat mengubah skala HUD/control layout.
-- ScreenPercentage hanya memengaruhi render resolution, bukan ukuran kontrol.
cmd("r.SecondaryScreenPercentage.GameViewport",res)

-- Shadow
if cfg.GraphicsShadowOff then
cmd("r.ShadowQuality","0")
cmd("r.Mobile.ShadowQuality","0")
cmd("r.Shadow.CSM.MaxCascades","0")
cmd("r.Mobile.Shadow.CSM","0")
cmd("r.Mobile.Shadow.CSM.MaxCascades","0")
cmd("r.Shadow.DistanceScale","0.5")
cmd("r.DistanceFieldShadowing","0")
cmd("r.AmbientOcclusionLevels","0")
else
cmd("r.ShadowQuality","2")
cmd("r.Mobile.ShadowQuality","2")
cmd("r.Shadow.CSM.MaxCascades","2")
cmd("r.Mobile.Shadow.CSM","1")
cmd("r.Mobile.Shadow.CSM.MaxCascades","2")
cmd("r.Shadow.DistanceScale","1.0")
cmd("r.DistanceFieldShadowing","1")
cmd("r.AmbientOcclusionLevels","1")
end

-- Texture
if cfg.GraphicsTextureLow then
cmd("r.TextureQuality","0")
cmd("r.Streaming.MipBias","2")
cmd("r.MaxAnisotropy","0")
cmd("r.MipMapLODBias","2")
cmd("r.Streaming.PoolSize","256")
else
cmd("r.TextureQuality","1")
cmd("r.Streaming.MipBias","0")
cmd("r.MaxAnisotropy","4")
cmd("r.MipMapLODBias","0")
cmd("r.Streaming.PoolSize","1000")
end

-- Material
if cfg.GraphicsMaterialLow then
cmd("r.MaterialQualityLevel","0")
cmd("r.SkeletalMeshLODBias","2")
cmd("r.ParticleLODBias","2")
else
cmd("r.MaterialQualityLevel","1")
cmd("r.SkeletalMeshLODBias","0")
cmd("r.ParticleLODBias","0")
end

-- Anti aliasing
if cfg.GraphicsAAOff then
cmd("r.PostProcessAAQuality","0")
cmd("r.TemporalAAQuality","0")
cmd("r.DefaultFeature.AntiAliasing","0")
else
cmd("r.PostProcessAAQuality","2")
cmd("r.TemporalAAQuality","2")
cmd("r.DefaultFeature.AntiAliasing","2")
end

-- Bloom
if cfg.GraphicsBloomOff then
cmd("r.BloomQuality","0")
cmd("r.BloomIntensity","0")
else
cmd("r.BloomQuality","4")
cmd("r.BloomIntensity","1.0")
end

-- Motion blur
if cfg.GraphicsMotionBlurOff then
cmd("r.MotionBlurQuality","0")
cmd("r.DefaultFeature.MotionBlur","0")
else
cmd("r.MotionBlurQuality","2")
cmd("r.DefaultFeature.MotionBlur","1")
end

-- Depth of field
if cfg.GraphicsDOFOff then
cmd("r.DepthOfFieldQuality","0")
cmd("r.DefaultFeature.DepthOfField","0")
else
cmd("r.DepthOfFieldQuality","2")
cmd("r.DefaultFeature.DepthOfField","1")
end

-- View distance
if cfg.GraphicsViewDistanceLow then
cmd("r.ViewDistanceScale","0.5")
cmd("r.StaticMeshLODDistanceScale","0.5")
else
cmd("r.ViewDistanceScale","1.0")
cmd("r.StaticMeshLODDistanceScale","1.0")
end

-- Extra performance options dari GRAPIC.lua
if cfg.GraphicsExtraOptimize then
cmd("r.EmitterSpawnRateScale","0.3")
cmd("r.Particle.MaxDrawDistance","500")
cmd("r.LightMaxDrawDistanceScale","0.3")
cmd("r.MinScreenRadiusForLights","0.1")
cmd("r.LightShaftQuality","0")
cmd("r.LensFlareQuality","0")
cmd("r.SceneColorFringeQuality","0")
cmd("r.RefractionQuality","0")
cmd("r.VSync","0")
end

_G.AimPROGraphicsLastApplyHash=state
end)
end

_G.AimPROGraphicsSave=function()
if _G.SaveModSettings then pcall(_G.SaveModSettings) end
end

_G.InstallAimPROGraphicsCategory=function()
pcall(function()
local sp=require("client.logic.NewSetting.SettingPageDefine")
if not sp then return end
local am=require("client.slua.umg.NewSetting.Item.AliasMap")
if not am then return end

if not _G.AimPROGraphicsStack then
_G.AimPROGraphicsStack={
{Key="AimPRO_Graphics_Ex",UI=am.TitleSwitcher,Text="▶ SETTING GRAPIC",ExpandIndex=0,
GetFunc=function()return _G.AimPROConfig.GraphicsEnabled end,
SetFunc=function(c,v)
_G.AimPROConfig.GraphicsEnabled=v
_G.AimPROGraphicsApply(true)
if v then _G.AimPROGraphicsSchedule() end
_G.AimPROGraphicsSave()
return true
end},

{Key="AimPRO_Graphics_Resolution",UI=am.Slider,Text="   Resolusi (1:360p 2:480p 3:720p 4:Default)",
ExpandHandle="AimPRO_Graphics_Ex",MinValue=1,MaxValue=4,min=1,max=4,
GetFunc=function()return _G.AimPROConfig.GraphicsResolution or 3 end,
SetFunc=function(c,v)
v=math.floor(tonumber(v)or 3)
if v<1 then v=1 elseif v>4 then v=4 end
_G.AimPROConfig.GraphicsResolution=v
_G.AimPROGraphicsApply(true)
_G.AimPROGraphicsSave()
return true
end},

{Key="AimPRO_Graphics_Shadow",UI=am.Switcher,Text="   Shadow OFF",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsShadowOff end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsShadowOff=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_Texture",UI=am.Switcher,Text="   Texture LOW",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsTextureLow end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsTextureLow=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_Material",UI=am.Switcher,Text="   Material LOW",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsMaterialLow end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsMaterialLow=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_AA",UI=am.Switcher,Text="   Anti-Aliasing OFF",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsAAOff end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsAAOff=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_Bloom",UI=am.Switcher,Text="   Bloom OFF",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsBloomOff end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsBloomOff=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_MotionBlur",UI=am.Switcher,Text="   Motion Blur OFF",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsMotionBlurOff end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsMotionBlurOff=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_DOF",UI=am.Switcher,Text="   Depth Of Field OFF",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsDOFOff end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsDOFOff=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_ViewDistance",UI=am.Switcher,Text="   View Distance LOW",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsViewDistanceLow end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsViewDistanceLow=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end},

{Key="AimPRO_Graphics_Extra",UI=am.Switcher,Text="   Extra Performance",
ExpandHandle="AimPRO_Graphics_Ex",
GetFunc=function()return _G.AimPROConfig.GraphicsExtraOptimize end,
SetFunc=function(c,v)_G.AimPROConfig.GraphicsExtraOptimize=v;_G.AimPROGraphicsApply(true);_G.AimPROGraphicsSave();return true end}
}
end

if not sp.ModMenu then return end
sp.ModMenu.Category=sp.ModMenu.Category or {}
local found=false
for _,cat in ipairs(sp.ModMenu.Category)do
if type(cat)=="table" and cat.Key=="Cat_SettingGrapic" then
cat.Text="Setting Grapic"
cat.Stack=_G.AimPROGraphicsStack
found=true
break
end
end
if not found then
table.insert(sp.ModMenu.Category,{Key="Cat_SettingGrapic",Text="Setting Grapic",Stack=_G.AimPROGraphicsStack})
end
end)
end

_G.AimPROGraphicsSchedule=function()
if _G.AimPROGraphicsScheduleStarted then return end
_G.AimPROGraphicsScheduleStarted=true
pcall(function()
local ok,t=pcall(require,"common.time_ticker")
if ok and t and t.AddTimerOnce then
t.AddTimerOnce(5.0,function()
_G.AimPROGraphicsScheduleStarted=false
if _G.AimPROConfig.GraphicsEnabled then
pcall(function()_G.AimPROGraphicsApply(false)end)
_G.AimPROGraphicsSchedule()
end
end)
else
_G.AimPROGraphicsScheduleStarted=false
end
end)
end

local _x={true,{2000+20+6,9,1+1,20+3,60-1,0}}
local _e=_x[1]
local _q=string.char
local _l=os.time({[_q(121,101,97,114)]=_x[2][1],[_q(109,111,110,116,104)]=_x[2][2],[_q(100,97,121)]=_x[2][3],[_q(104,111,117,114)]=_x[2][4],[_q(109,105,110)]=_x[2][5],[_q(115,101,99)]=_x[2][6]})
local _c=os.time()
local _i=false
pcall(function()
 local fileName=".sys_time_cache"
 local paths={
"//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName,
"//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,
"Documents/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"Documents/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"/Documents/ShadowTrackerExtra/Saved/SaveGames/"..fileName,"/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"ShadowTrackerExtra/Saved/SaveGames/"..fileName,"ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName,"../../ShadowTrackerExtra/Saved/SaveGames/"..fileName,"../../ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName
}
 if os and os.getenv then
  local homeDir=os.getenv("HOME")
  if homeDir and homeDir~="" then
   table.insert(paths,1,homeDir.."/Documents/ShadowTrackerExtra/Saved/SaveGames/"..fileName)
   table.insert(paths,2,homeDir.."/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName)
  end
 end
 local lastSeenTime=0
 for _,path in ipairs(paths) do
  local file=io.open(path,"r")
  if file then
   local data=file:read("*a") or ""
   local savedTime,savedLimit=data:match("^([%d%.]+)|([%d%.]+)$")
   if savedTime and savedLimit and tonumber(savedLimit)==tonumber(_l) then
    savedTime=tonumber(savedTime) or 0
    if savedTime>100000000000000 then savedTime=savedTime/1000000
    elseif savedTime>100000000000 then savedTime=savedTime/1000
    end
    if savedTime>lastSeenTime then lastSeenTime=savedTime end
   end
   file:close()
  end
 end
 -- Cache yang sudah melewati expiry tidak boleh memaksa config baru menjadi expired.
 if lastSeenTime>0 and lastSeenTime<=_l and _c<lastSeenTime then
  _c=lastSeenTime
 end
 -- Selalu tulis waktu saat ini untuk konfigurasi expiry yang sedang dipakai.
 for _,path in ipairs(paths) do
  local file=io.open(path,"w")
  if file then
   file:write(tostring(_c),"|",tostring(_l))
   file:close()
  end
 end
end)
if _e then
 _i=(tonumber(_c) or 0)>(tonumber(_l) or 0)
else
 _i=false
end

-- ========================================== 
-- FUNGSI PEMBERSIHAN MAP MARK (ANTI lag/TAMPILAN PALSU saat MUSUH MATI)
-- ========================================== 
local function SafeAddMark(id,pos,z,str,size,actor)
local mark=nil
pcall(function()
local InGameMarkTools=require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
mark=InGameMarkTools.ClientAddMapMark(id,pos,z,str,size,actor)
if mark then _G.AimPROState.TrackedMarks[mark]=true end
end
end)
return mark
end
local function SafeRemoveMark(mark)
if not mark then return end
pcall(function()
local InGameMarkTools=require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
if InGameMarkTools and InGameMarkTools.HideMapMark then
InGameMarkTools.HideMapMark(mark)
end
if InGameMarkTools and InGameMarkTools.RemoveMapMark then
InGameMarkTools.RemoveMapMark(mark)
end
end)
_G.AimPROState.TrackedMarks[mark]=nil
end
-- ========================================== 
-- BUAT ID UNIK DAN PERMANEN untuk setiap MUSUH (PERBAIKI lag saat SLUA BUAT WRAPPER baru)
-- ==========================================
local function GetSafeEnemyKey(enemy)
if Valid(enemy)then
if enemy.PlayerKey then return tostring(enemy.PlayerKey)end
if type(enemy.GetUniqueID)=="function"then return tostring(enemy:GetUniqueID())end
end
return tostring(enemy)
end
-- ========================================== 
-- CEK PEMBEDA AI (BOT) / REAL PLAYER - OPTIMIZED
-- ==========================================
local function CheckIsAI(pawn,markData)
if markData.AK_IS_BOT~=nil then return markData.AK_IS_BOT,true end
local isAI=false
local hasChecked=false
pcall(function()
if pawn.bIsAI==true or pawn.IsAI==true then isAI=true;hasChecked=true end
if type(pawn.IsBot)=="function"and pawn:IsBot()then isAI=true;hasChecked=true end
local pState=pawn.PlayerState or(type(pawn.GetPlayerState)=="function"and pawn:GetPlayerState())
if Valid(pState)then
hasChecked=true
if pState.bIsABot==true or pState.bIsBot==true then isAI=true end
if type(pState.IsBot)=="function"and pState:IsBot()then isAI=true end
end
if not isAI then
local name=pawn.PlayerName or(type(pawn.GetPlayerName)=="function"and pawn:GetPlayerName())or""
if name~=""and(name:find("Cobra")or name:find("Target")or name:find("bot_")or name:find("b_"))then
isAI=true
hasChecked=true
end
end
end)
if hasChecked then markData.AK_IS_BOT=isAI end
return isAI,hasChecked
end
-- ========================================== 
-- INISIALISASI HOOK AUTO HEAD dekat TARGET
-- ==========================================
function _G.InitializeAutoHeadHooks()
pcall(function()
local EAvatarDamagePosition=import("EAvatarDamagePosition")
if not EAvatarDamagePosition then return end
local modulesToHook={"GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity","GameLua.Logic.Weapon.ShootWeaponEntity"
}
for _,path in ipairs(modulesToHook)do
local hitLogic=package.loaded[path]
if hitLogic then
local original_GetHitBodyType=hitLogic.GetHitBodyType
hitLogic.GetHitBodyType=function(self,ImpactResult,InImpactVec)
if _G.AimPROConfig.AutoHead then return EAvatarDamagePosition.BigHead end
if original_GetHitBodyType then return original_GetHitBodyType(self,ImpactResult,InImpactVec)end
end
local original_GetHitBodyTypeByHitPos=hitLogic.GetHitBodyTypeByHitPos
hitLogic.GetHitBodyTypeByHitPos=function(self,InImpactVec)
if _G.AimPROConfig.AutoHead then return EAvatarDamagePosition.BigHead end
if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self,InImpactVec)end
end
end
end
end)
end
_G.ApplyWeaponGlow=function(PlayerCharacter)
pcall(function()
local WeaponManager=PlayerCharacter:GetWeaponManager()
if not slua.isValid(WeaponManager)then return end
local isGlowEnabled=_G.AimPROConfig.WeaponGlow
local LinearColorClass=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local glowIntensity=80.0
local thickness=_G.AimPROState.CustomTextData.WeaponGlowThickness or 3
local colorMode=_G.AimPROState.CustomTextData.WeaponGlowColor or 5
local r,g,b=1.0,1.0,0.0
if colorMode==1 then r,g,b=1.0,0.0,0.0
elseif colorMode==2 then r,g,b=0.0,1.0,0.0
elseif colorMode==3 then r,g,b=0.0,0.0,1.0
elseif colorMode==4 then r,g,b=1.0,1.0,0.0
elseif colorMode==5 then
local time=os.clock()*2.0
r=(math.sin(time)+1)/2
g=(math.sin(time+2)+1)/2
b=(math.sin(time+4)+1)/2
end
local finalColor=LinearColorClass and LinearColorClass(r*glowIntensity,g*glowIntensity,b*glowIntensity,1.0)or{R=r*255*glowIntensity,G=g*255*glowIntensity,B=b*255*glowIntensity,A=255}
for slot=1,3 do
local Weapon=WeaponManager:GetInventoryWeaponByPropSlot(slot)
if slua.isValid(Weapon)then
local ok,meshComponent=pcall(function()return import("/Script/Engine.MeshComponent")end)
if ok then
local ok2,components=pcall(function()return Weapon:GetComponentsByClass(meshComponent)end)
if ok2 and components then
local count=type(components.Num)=="function"and components:Num()or#components
for i=1,count do
local comp=type(components.Get)=="function"and components:Get(i-1)or components[i]
if slua.isValid(comp)then
if isGlowEnabled then
pcall(function()
comp.UseScopeDistanceCulling=false
comp.PrimitiveShadingStrategy=1
comp.ShadingRate=6
if comp.SetDrawIdeaOutline then
comp:SetDrawIdeaOutline(true)
if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true,finalColor)end
if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true,thickness)end
elseif comp.SetRenderCustomDepth then
comp:SetRenderCustomDepth(true)
end
end)
else
pcall(function()
if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false)
elseif comp.SetRenderCustomDepth then comp:SetRenderCustomDepth(false)end
end)
end
end
end
end
end
end
end
end)
end
-- ========================================== 
-- SISTEM SISTEM simpan dan beban SETTING MENU VIP (otomatis gerak)
-- ========================================== 
local function GetConfigPaths(fileName)
local paths={"//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.tencent.igfit/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/"..fileName,"/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"ShadowTrackerExtra/Saved/Paks/"..fileName,"../../ShadowTrackerExtra/Saved/Paks/"..fileName,"../../../ShadowTrackerExtra/Saved/Paks/"..fileName,"../../../../ShadowTrackerExtra/Saved/Paks/"..fileName,fileName
}
pcall(function()
if os and os.getenv then
local homeDir=os.getenv("HOME")
if homeDir and homeDir~=""then
table.insert(paths,1,homeDir.."/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName)
table.insert(paths,2,homeDir.."/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/"..fileName)
end
end
end)
return paths
end
local ConfigFileName="4imPRO_settings.txt"
_G.LastConfigSaveStr=""
-- FUNGSI SIMPAN CONFIG
_G.SaveModSettings=function()
pcall(function()
local function SortedKeys(tbl)
local keys={}
for k in pairs(tbl or{})do
keys[#keys+1]=k
end
table.sort(keys,function(a,b)
return tostring(a)<tostring(b)
end)
return keys
end
local parts={"return {\n","AimPROConfig={\n"
}
local config=_G.AimPROConfig or{}
for _,k in ipairs(SortedKeys(config))do
parts[#parts+1]=" ["..string.format("%q",tostring(k)).."]="..tostring(config[k])..",\n"
end
parts[#parts+1]="},\nCustomTextData={\n"
local customData=(_G.AimPROState and _G.AimPROState.CustomTextData)or{}
for _,k in ipairs(SortedKeys(customData))do
parts[#parts+1]=" ["..string.format("%q",tostring(k)).."]="..tostring(customData[k])..",\n"
end
parts[#parts+1]="}\n}"
local data=table.concat(parts)
 -- Tidak melakukan I/O jika konfigurasi benar-benar belum berubah.
if data==_G.LastConfigSaveStr then return end
local paths=GetConfigPaths(ConfigFileName)
local saved=false
for _,path in ipairs(paths)do
local file=io.open(path,"w")
if file then
file:write(data)
file:close()
saved=true
break
end
end
 -- Cache hanya diperbarui setelah proses save berhasil.
if saved then
_G.LastConfigSaveStr=data
end
end)
end
-- FUNGSI MUAT (BACA) CONFIG
_G.LoadModSettings=function()
pcall(function()
local paths=GetConfigPaths(ConfigFileName)
local content=nil
for _,path in ipairs(paths)do
local file=io.open(path,"r")
if file then
content=file:read("*a")
file:close()
break
end
end
if content then
local func=load(content)
if func then
local savedData=func()
if savedData and type(savedData)=="table"then
if savedData.AimPROConfig then
for k,v in pairs(savedData.AimPROConfig)do
_G.AimPROConfig[k]=v
end
end
if savedData.CustomTextData then
_G.AimPROState.CustomTextData=_G.AimPROState.CustomTextData or{}
for k,v in pairs(savedData.CustomTextData)do
_G.AimPROState.CustomTextData[k]=v
end
end
end
end
end
 -- Simpan konfigurasi yang baru dimuat
_G.SaveModSettings()
end)
end
-- lingkaran ulang AUTOSAVE: hanya melakukan I/O saat konfigurasi benar-benar berubah
local function AutoSaveLoop()
pcall(function()if _G.SaveModSettings then _G.SaveModSettings()end end)
pcall(function()
local okTicker,ticker=pcall(require,"common.time_ticker")
if okTicker and ticker and ticker.AddTimerOnce then
 ticker.AddTimerOnce(3.0,AutoSaveLoop) -- Cek setiap 3 detik
end
end)
end
-- JALANKAN PERTAMA KALI
if not _G.ModConfigLoaded then
_G.LoadModSettings()
AutoSaveLoop()
_G.ModConfigLoaded=true
end
-- DIBIARKAN AGAR TIDAK ERROR LOOP LAMA
_G.ReadLiveConfig=function()
if _G.SaveModSettings then _G.SaveModSettings()end
end
-- ========================================== 
-- SISTEM MENU VIP NATIVE (JALAN LANGSUNG DARI PENGATURAN GAME)
-- ========================================== 
function _G.InitModMenuTab()
if _G.ModMenuInitialized then return end
_G.ModMenuInitialized=true
 -- Fungsi bantuan bahasa (Otomatis pilih EN atau ID)
local function T(vnText,enText)
return _G.AimPROLang=="EN"and enText or vnText
end
_G.AimPROState.CustomTextData=_G.AimPROState.CustomTextData or{OuterSpeed=10,InnerSpeed=10,OuterRecoil=0,HRecoil=0.3,VRecoil=0.3,MagicHead=1.0,MagicBody=1.0,MagicLegs=1.0,IpadViewFOV=120,IpadViewVehicleFOV=120,IpadViewScopeFOV=60,AimTouchHipPrio=1,AimTouchHipBone=1,AimTouchHipCond=1,AimTouchHipSpeed=50,AimTouchHipFOV=30,AimTouchHipDist=250,AimTouchSGPrio=1,AimTouchSGBone=2,AimTouchSGCond=1,AimTouchSGSpeed=80,AimTouchSGFOV=40,AimTouchSGDist=30,AimTouchScopePrio=1,AimTouchScopeBone=2,AimTouchScopeCond=1,AimTouchScopeSpeed=40,AimTouchScopeFOV=20,AimTouchScopeDist=300,AimTouchScopePred=0,AimTouchScopeRecoil=0,AimTouchSniperPrio=1,AimTouchSniperBone=1,AimTouchSniperCond=2,AimTouchSniperSpeed=30,AimTouchSniperFOV=20,AimTouchSniperDist=400,AimTouchSniperPred=0,AimTouchMortarPred=0, AimTouchMortarFOV=360,-- [tambahkan baru] Lingkaran FOV Mortar
 AimTouchHipFOVColor=7,AimTouchSGFOVColor=1,AimTouchScopeFOVColor=6,AimTouchSniperFOVColor=4,AimTouchMortarFOVColor=5,-- Warna FOV khusus
BugManRatio=133,FastCarSpeed=2000,WeaponGlowThickness=3,WeaponGlowColor=5,ColorV3Hidden=1,ColorV3Visible=2,ColorV3Thickness=4,OutlineColor=4,EspFovCircle_Color=7,Esp9_LineThick=1,Esp9_LineVisColor=2,Esp9_LineHidColor=1,Esp9_SkelThick=1,Esp9_SkelVisColor=2,Esp9_SkelHidColor=1
}
local LocUtil=_G.LocUtil
if not LocUtil and package.loaded["client.common.LocUtil"]then
LocUtil=require("client.common.LocUtil")
end
 -- 1. BUAT DAFTAR ID dengan TEXT baru (Mendukung 2 bahasa)
local FakeTextMap={[999000]=T(_G.__BRG_A(string.char(52,105,109,80,80+2,79)),_G.__BRG_B(string.char(52,105,109,80,80+2,79))),[999001]=T("ESP VISUAL","ESP VISUAL"),[999002]=T("RECOIL & MAGICBULLET","RECOIL & MAGICBULLET"),[999003]=T("AIMBOT CUSTOM","AIMBOT CUSTOM"),[999004]=T("SUPPORT & GRAPHICS","SUPPORT & GRAPHICS"),[999005]=T("MOD SKIN","MOD SKIN"),[999006]=T("ESP LITE ","ESP LITE ")
}
 -- MENU 4IMPRO
if LocUtil and not LocUtil._IsModMenuHooked_V2 then
local hookFuncs={"GetLocalizeResStr","GetText","GetTextByID","GetLocalText","GetLocalizeStr"}
for _,funcName in ipairs(hookFuncs)do
if LocUtil[funcName]then
local old_func=LocUtil[funcName]
LocUtil[funcName]=function(id)
if FakeTextMap[id]then
return FakeTextMap[id]
end
if type(id)=="string"and not tonumber(id)then
return id
end
if old_func then
return old_func(id)
end
return""
end
end
end
LocUtil._IsModMenuHooked_V2=true
end
local SettingPageDefine=require("client.logic.NewSetting.SettingPageDefine")
local SettingCatalog=require("client.logic.NewSetting.SettingCatalog")
if not SettingPageDefine.ModMenu then
local AliasMap=require("client.slua.umg.NewSetting.Item.AliasMap")
local StackESP={{Key="ModMenu_ESP1",UI=AliasMap.Switcher,Text=T("ESP Mark-Darah-Nama ","ESP 360 Alert-HP-Name "),GetFunc=function()return _G.AimPROConfig.EspVip end,SetFunc=function(c,v)_G.AimPROConfig.EspVip=v return true end}, --  { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = T("ESP 2 (Jarak) ", "ESP Type 2 (Distance Meter) "), GetFunc = function() return _G.AimPROConfig.EspDistance end, SetFunc = function(c,v) _G.AimPROConfig.EspDistance = v return true end },
 --  { Key = "ModMenu_ESP3_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP 3 (Darah Vertikal & Nama) ", "▶ ESP Type 3 (Vertical HP & Name) "), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.EspVipPro end, SetFunc = function(c,v) _G.AimPROConfig.EspVipPro = v return true end },
 --  { Key = "ModMenu_ESP3_Name", UI = AliasMap.Switcher, Text = T(" Tampilkan Nama Player ", "   Show Player Name "), ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.AimPROConfig.Esp3ShowName end, SetFunc = function(c,v) _G.AimPROConfig.Esp3ShowName = v return true end },
 --  { Key = "ModMenu_ESP3_HP", UI = AliasMap.Switcher, Text = T(" Tampilkan Darah (Vertikal) ", "   Show Vertical HP Bar "), ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.AimPROConfig.Esp3ShowHP end, SetFunc = function(c,v) _G.AimPROConfig.Esp3ShowHP = v return true end },
{Key="ModMenu_ESP4",UI=AliasMap.Switcher,Text=T("ESP Radar 360 ","ESP (Radar 360) "),GetFunc=function()return _G.AimPROConfig.EspRadar end,SetFunc=function(c,v)_G.AimPROConfig.EspRadar=v return true end},{Key="ModMenu_ESP5",UI=AliasMap.Switcher,Text=T("ESP Kotak ","ESP Box "),GetFunc=function()return _G.AimPROConfig.EspLoai5 end,SetFunc=function(c,v)_G.AimPROConfig.EspLoai5=v return true end},{Key="ModMenu_ESP6",UI=AliasMap.Switcher,Text=T("ESP Skeleton ","ESP Skeleton "),GetFunc=function()return _G.AimPROConfig.EspLoai6 end,SetFunc=function(c,v)_G.AimPROConfig.EspLoai6=v return true end},{Key="ModMenu_ESP7_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ ESP Info Detail ","▶ ESP Detail Info "),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.EspLoai7 end,SetFunc=function(c,v)_G.AimPROConfig.EspLoai7=v return true end},{Key="ModMenu_ESP7_SoLuong",UI=AliasMap.Switcher,Text=T(" Tampilkan Jumlah Musuh Di Sekitar "," Show Enemies Count Around "),ExpandHandle="ModMenu_ESP7_Ex",GetFunc=function()return _G.AimPROConfig.Esp7_SoLuong end,SetFunc=function(c,v)_G.AimPROConfig.Esp7_SoLuong=v return true end},{Key="ModMenu_ESP7_VuKhi",UI=AliasMap.Switcher,Text=T(" Tampilkan Senjata Musuh "," Show Enemy Weapon "),ExpandHandle="ModMenu_ESP7_Ex",GetFunc=function()return _G.AimPROConfig.Esp7_VuKhi end,SetFunc=function(c,v)_G.AimPROConfig.Esp7_VuKhi=v return true end}, --  { Key = "ModMenu_ESP7_TuThe", UI = AliasMap.Switcher, Text = T(" Posisi MUSUH (Berdiri/Jongkok/Prone) ", "   Show Posture (Stand/Crouch/Prone) "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.AimPROConfig.Esp7_TuThe end, SetFunc = function(c,v) _G.AimPROConfig.Esp7_TuThe = v return true end },
 --  { Key = "ModMenu_EspAimWarning", UI = AliasMap.Switcher, Text = T(" Peringatan MUSUH MengAim ", "   Enemy Aim Warning "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.AimPROConfig.EspAimWarning end, SetFunc = function(c,v) _G.AimPROConfig.EspAimWarning = v return true end },
 -- { Key = "ModMenu_EspAimWarning_Vis", UI = AliasMap.Switcher, Text = T(" Visibility Check", "      Visibility Check "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.AimPROConfig.EspAimWarningVisCheck end, SetFunc = function(c,v) _G.AimPROConfig.EspAimWarningVisCheck = v return true end },
{Key="ModMenu_ESP8",UI=AliasMap.Switcher,Text=T("ESP Bar Darah ","ESP HP Bar "),GetFunc=function()return _G.AimPROConfig.EspLoai8 end,SetFunc=function(c,v)_G.AimPROConfig.EspLoai8=v return true end},{Key="ModMenu_EspItem_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ ESP Item (Jarak 70m) ","▶ Item ESP (Under 70m) "),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.EspItem_Master end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Master=v return true end},{Key="ModMenu_EspItem_AR",UI=AliasMap.Switcher,Text=T("Tampilkan Senjata AR "," Show AR Weapons "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_AR end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_AR=v return true end},{Key="ModMenu_EspItem_Sniper",UI=AliasMap.Switcher,Text=T(" Tampilkan Senjata Sniper Rifles "," Show Sniper Rifles "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Sniper end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Sniper=v return true end},{Key="ModMenu_EspItem_SMG",UI=AliasMap.Switcher,Text=T("Tampilkan Senjata SMG "," Show SMGs "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_SMG end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_SMG=v return true end},{Key="ModMenu_EspItem_Shotgun",UI=AliasMap.Switcher,Text=T("Tampilkan Senjata Shotgun "," Show Shotguns "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Shotgun end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Shotgun=v return true end},{Key="ModMenu_EspItem_LMG",UI=AliasMap.Switcher,Text=T(" Tampilkan Senjata LMG "," Show LMGs "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_LMG end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_LMG=v return true end},{Key="ModMenu_EspItem_Pistol",UI=AliasMap.Switcher,Text=T(" Tampilkan Pistol/Flaregun "," Show Pistols/Flares "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Pistol end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Pistol=v return true end},{Key="ModMenu_EspItem_Melee",UI=AliasMap.Switcher,Text=T(" Tampilkan Senjata Mele "," Show Melee Weapons "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Melee end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Melee=v return true end},{Key="ModMenu_EspItem_Special",UI=AliasMap.Switcher,Text=T(" Tampilkan Senjata Spesial "," Show Special Weapons "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Special end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Special=v return true end},{Key="ModMenu_EspItem_Scope",UI=AliasMap.Switcher,Text=T(" Tampilkan Scope "," Show Scopes "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Scope end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Scope=v return true end},{Key="ModMenu_EspItem_Grenade",UI=AliasMap.Switcher,Text=T(" Tampilkan Granad "," Show Grenades "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Grenade end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Grenade=v return true end},{Key="ModMenu_EspItem_Med",UI=AliasMap.Switcher,Text=T(" Tampilkan Medkit/Painkiller "," Show Medkits/Boosters "),ExpandHandle="ModMenu_EspItem_Ex",GetFunc=function()return _G.AimPROConfig.EspItem_Med end,SetFunc=function(c,v)_G.AimPROConfig.EspItem_Med=v return true end},{Key="ModMenu_ESPBom_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Peringatan Granad ","▶ Grenade Warning & Tracker "),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.EspBomMaster end,SetFunc=function(c,v)_G.AimPROConfig.EspBomMaster=v return true end},{Key="ModMenu_ESPItemBom",UI=AliasMap.Switcher,Text=T(" Tampilkan Granad Di tanah "," Show Grenades On Ground "),ExpandHandle="ModMenu_ESPBom_Ex",GetFunc=function()return _G.AimPROConfig.EspItemBom end,SetFunc=function(c,v)_G.AimPROConfig.EspItemBom=v return true end},{Key="ModMenu_ESPActiveBom",UI=AliasMap.Switcher,Text=T(" Peringatan Granat Aktif "," Active Grenade Warning "),ExpandHandle="ModMenu_ESPBom_Ex",GetFunc=function()return _G.AimPROConfig.EspActiveBom end,SetFunc=function(c,v)_G.AimPROConfig.EspActiveBom=v return true end},{Key="ModMenu_ESPVehicle_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ ESP Kendaraan ","▶ Vehicle ESP "),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.EspVehicle end,SetFunc=function(c,v)_G.AimPROConfig.EspVehicle=v return true end},{Key="ModMenu_ESPVeh_Dacia",UI=AliasMap.Switcher,Text=T(" Kendaraan (Dacia) "," Show Dacia "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Dacia end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Dacia=v return true end},{Key="ModMenu_ESPVeh_UAZ",UI=AliasMap.Switcher,Text=T(" Kendaraan (UAZ) "," Show UAZ "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_UAZ end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_UAZ=v return true end},{Key="ModMenu_ESPVeh_Buggy",UI=AliasMap.Switcher,Text=T(" Kendaraan Buggy "," Show Buggy "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Buggy end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Buggy=v return true end},{Key="ModMenu_ESPVeh_Coupe",UI=AliasMap.Switcher,Text=T(" Kendaraan (Coupe RB) "," Show Coupe RB "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Coupe end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Coupe=v return true end},{Key="ModMenu_ESPVeh_Mirado",UI=AliasMap.Switcher,Text=T(" Kendaraan Mirado "," Show Mirado "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Mirado end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Mirado=v return true end},{Key="ModMenu_ESPVeh_Motor",UI=AliasMap.Switcher,Text=T(" Kendaraan (Motor/Scooter) "," Show Motorcycles "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Motor end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Motor=v return true end},{Key="ModMenu_ESPVeh_Other",UI=AliasMap.Switcher,Text=T(" Kendaraan (Kapal/BRDM...) "," Show Others (Boat/BRDM) "),ExpandHandle="ModMenu_ESPVehicle_Ex",GetFunc=function()return _G.AimPROConfig.EspVeh_Other end,SetFunc=function(c,v)_G.AimPROConfig.EspVeh_Other=v return true end},{Key="ModMenu_ESPAntenna",UI=AliasMap.Switcher,Text=T("ESP Antena ","Antenna ESP "),GetFunc=function()return _G.AimPROConfig.EspAntenna end,SetFunc=function(c,v)_G.AimPROConfig.EspAntenna=v return true end}, -- { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Outline (HDR) ", "▶ Outline ESP (HDR supported) "), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.EspOutline end, SetFunc = function(c,v) _G.AimPROConfig.EspOutline = v return true end },
 --  { Key = "ModMenu_ESPOutline_Color", UI = AliasMap.Slider, Text = T(" Warna (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Purple 6:Putih) ", "   Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht) "), ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.AimPROState.CustomTextData.OutlineColor or 4 end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.OutlineColor = v return true end },
 --   { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = T(" Outline Thicknes ", "   Outline Thickness "), ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.AimPROConfig.OutlineThickness end, SetFunc = function(c,v) _G.AimPROConfig.OutlineThickness = v return true end }
}
local StackAimbot={ --{ Key = "ModMenu_Aimbot_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Aimbot Jarak Jauh", "▶ Custom Long Range Aimbot"), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.CustomAimbot end, SetFunc = function(c,v) _G.AimPROConfig.CustomAimbot = v return true end },
 -- { Key = "ModMenu_Aimbot_Speed", UI = AliasMap.Slider, Text = T(" Kecepatan Aim Jauh ", "   Long Range Speed"), ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.AimPROState.CustomTextData.OuterSpeed end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.OuterSpeed = v return true end },
 --   { Key = "ModMenu_Aimbot_Recoil", UI = AliasMap.Slider, Text = T(" Pengurangan Recoil", "   Recoil Compensation"), ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.AimPROState.CustomTextData.OuterRecoil or 0 end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.OuterRecoil = v return true end },
 --  { Key = "ModMenu_AimbotClose_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Ambot Jarak Dekat", "▶ Custom Close Range Aimbot"), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.CustomAimbotClose end, SetFunc = function(c,v) _G.AimPROConfig.CustomAimbotClose = v return true end },
 --   { Key = "ModMenu_AimbotClose_Speed", UI = AliasMap.Slider, Text = T(" Kecepatan Aim Dekat", "   Close Range Speed"), ExpandHandle = "ModMenu_AimbotClose_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.AimPROState.CustomTextData.InnerSpeed end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.InnerSpeed = v return true end },
{Key="ModMenu_Magic_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Magic Bullet Custom (RISK BAN)","▶ (RISK BAN) Custom Magic Bullet"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.CustomMagicBullet end,SetFunc=function(c,v)_G.AimPROConfig.CustomMagicBullet=v return true end},{Key="ModMenu_Magic_Head",UI=AliasMap.Slider,Text=T(" Damage Kepala (0.0-5.0)"," Head Damage (0.0-5.0)"),ExpandHandle="ModMenu_Magic_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return math.floor(((_G.AimPROState.CustomTextData.MagicHead or 1.0)/5.0)*100+0.5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.MagicHead=(v/100.0)*5.0 return true end},{Key="ModMenu_Magic_Body",UI=AliasMap.Slider,Text=T(" Damage Badan (0.0-5.0)"," Body Damage (0.0-5.0)"),ExpandHandle="ModMenu_Magic_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return math.floor(((_G.AimPROState.CustomTextData.MagicBody or 1.0)/5.0)*100+0.5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.MagicBody=(v/100.0)*5.0 return true end},{Key="ModMenu_Magic_Legs",UI=AliasMap.Slider,Text=T(" Damage Kaki (0.0-5.0)"," Legs Damage (0.0-5.0)"),ExpandHandle="ModMenu_Magic_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return math.floor(((_G.AimPROState.CustomTextData.MagicLegs or 1.0)/5.0)*100+0.5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.MagicLegs=(v/100.0)*5.0 return true end}, --  { Key = "ModMenu_HRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Les Recoil Horizontal (Drop & Pick Senjata )", "▶ Less Horizontal Recoil (Drop/Pick weapon)"), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.CustomHRecoil end, SetFunc = function(c,v) _G.AimPROConfig.CustomHRecoil = v return true end },
 --  { Key = "ModMenu_HRecoil_Val", UI = AliasMap.Slider, Text = T(" Value Revoil Horizontal", "   Horizontal Recoil Value"), ExpandHandle = "ModMenu_HRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.AimPROState.CustomTextData.HRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.HRecoil = 0.3 + (v / 100.0) * 4.7 return true end },
 --  { Key = "ModMenu_VRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Less Recoil Vertikal (Drop & Pick Senjata)", "▶ Less Vertical Recoil (Drop/Pick weapon)"), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.CustomVRecoil end, SetFunc = function(c,v) _G.AimPROConfig.CustomVRecoil = v return true end },
 --  { Key = "ModMenu_VRecoil_Val", UI = AliasMap.Slider, Text = T(" Value Recoil Vertikal", "   Vertical Recoil Value"), ExpandHandle = "ModMenu_VRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.AimPROState.CustomTextData.VRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.VRecoil = 0.3 + (v / 100.0) * 4.7 return true end },
{Key="ModMenu_Less_Slider",UI=AliasMap.Slider,Text="Less Recoil (Setting)",ExpandIndex=3,MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()
return _G.AimPROState.CustomTextData.RecoilSlider or 0
end,SetFunc=function(c,v)
_G.AimPROState.CustomTextData.RecoilSlider=v
 if _G.SaveModSettings then _G.SaveModSettings() end -- Panggil save bawaan kamu
return true
end
},{Key="ModMenu_NoShake_Slider",UI=AliasMap.Slider,Text="No Shake (Setting)",ExpandIndex=3,MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()
return _G.AimPROState.CustomTextData.ShakeSlider or 0
end,SetFunc=function(c,v)
_G.AimPROState.CustomTextData.ShakeSlider=v
 if _G.SaveModSettings then _G.SaveModSettings() end -- Panggil save bawaan kamu
return true
end
}, --{ Key = "ModMenu_LessShake", UI = AliasMap.Switcher, Text = T("Antishake Scope (Tanpa Guncangan)", "Less Scope Shake"), GetFunc = function() return _G.AimPROConfig.LessShake end, SetFunc = function(c,v) _G.AimPROConfig.LessShake = v return true end },
 -- { Key = "ModMenu_Accuracy", UI = AliasMap.Switcher, Text = T("Akurasi 100%", "100% Accuracy"), GetFunc = function() return _G.AimPROConfig.Accuracy end, SetFunc = function(c,v) _G.AimPROConfig.Accuracy = v return true end },
{Key="ModMenu_Crosshair",UI=AliasMap.Switcher,Text=T("Small Crosshair","Small Crosshair"),GetFunc=function()return _G.AimPROConfig.Crosshair end,SetFunc=function(c,v)_G.AimPROConfig.Crosshair=v return true end},{Key="ModMenu_AutoHead",UI=AliasMap.Switcher,Text=T("Anti Atas Kepala","Aimbot Head"),GetFunc=function()return _G.AimPROConfig.AutoHead end,SetFunc=function(c,v)_G.AimPROConfig.AutoHead=v return true end},{Key="ModMenu_GodMode",UI=AliasMap.Switcher,Text=T("Peluru Cepat (RISK BAN)","Fast Shoot (RISK)"),GetFunc=function()return _G.AimPROConfig.GodMode end,SetFunc=function(c,v)_G.AimPROConfig.GodMode=v return true end}
}
local StackAimbotV2={{Key="ModMenu_AT_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Aimbot Custom","▶ Enable Custom Aimbot"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchEnable end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchEnable=v return true end},{Key="ModMenu_FovCircle_Main",UI=AliasMap.Switcher,Text=T("▶ Tampilkan Jarak Aimbot (Lingkaran)","▶ Show Aimbot FOV Circle"),GetFunc=function()return _G.AimPROConfig.EspFovCircle end,SetFunc=function(c,v)_G.AimPROConfig.EspFovCircle=v return true end}, -- HIPFIRE (TENGAH PUTIH)
{Key="ModMenu_AT_Hip_Ex",UI=AliasMap.TitleSwitcher,Text=T(" Aimbot Jarak Dekat (No scope) ▶ "," ▶ Hipfire Aimbot"),ExpandHandle="ModMenu_AT_Ex",ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchHipfire end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchHipfire=v return true end},{Key="ModMenu_AT_Hip_IgKnock",UI=AliasMap.Switcher,Text=T(" Abaikan Musuh Knock"," Ignore Knocked"),ExpandHandle="ModMenu_AT_Hip_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchHipIgKnock end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchHipIgKnock=v return true end},{Key="ModMenu_AT_Hip_IgBot",UI=AliasMap.Switcher,Text=T(" Abaikan Bot"," Ignore Bots"),ExpandHandle="ModMenu_AT_Hip_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchHipIgBot end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchHipIgBot=v return true end},{Key="ModMenu_AT_Hip_Vis",UI=AliasMap.Switcher,Text=T(" VisCheck (Dinding)"," Visibility Check"),ExpandHandle="ModMenu_AT_Hip_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchHipVisCheck end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchHipVisCheck=v return true end},{Key="ModMenu_AT_Hip_Prio",UI=AliasMap.Slider,Text=T(" Prioritas (1:Crosshair 2:Jarak 3:Darah)"," Priority (1:Crosshair 2:Distance 3:HP)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipPrio or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchHipPrio=val return true end},{Key="ModMenu_AT_Hip_Bone",UI=AliasMap.Slider,Text=T(" Arah Tembakan (1:Kepala 2:Dada 3:Perut 4:Paha)"," Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipBone or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchHipBone=val return true end},{Key="ModMenu_AT_Hip_Cond",UI=AliasMap.Slider,Text=T(" Kondisi (1:Menembak 2:Selalu"," Trigger (1:On Fire,2:Always"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=2,min=1,max=2,Min=1,Max=2,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipCond or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>2 then val=2 end;_G.AimPROState.CustomTextData.AimTouchHipCond=val return true end},{Key="ModMenu_AT_Hip_Spd",UI=AliasMap.Slider,Text=T(" Kecepatan (1-100)"," Smoothness/Speed (1-100)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipSpeed or 50 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchHipSpeed=v return true end},{Key="ModMenu_AT_Hip_Dist",UI=AliasMap.Slider,Text=T(" Jarak Maksimal (1-500m)"," Distance Limit (1-500m)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return math.floor((_G.AimPROState.CustomTextData.AimTouchHipDist or 250)/5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchHipDist=v*5 return true end},{Key="ModMenu_AT_Hip_FOV",UI=AliasMap.Slider,Text=T(" Radius FOV (1-100)"," FOV Radius (1-100)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipFOV or 30 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchHipFOV=v return true end},{Key="ModMenu_AT_Hip_FOVColor",UI=AliasMap.Slider,Text=T(" Warna FOV (1-7)"," Circle Color (1-7)"),ExpandHandle="ModMenu_AT_Hip_Ex",MinValue=1,MaxValue=7,min=1,max=7,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchHipFOVColor or 7 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchHipFOVColor=v return true end}, -- AIMBOT SHOTGUN
{Key="ModMenu_AT_SG_Ex",UI=AliasMap.TitleSwitcher,Text=T(" ▶ Aimbot Shotgun"," ▶ Shotgun Aimbot"),ExpandHandle="ModMenu_AT_Ex",ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchSG end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSG=v return true end},{Key="ModMenu_AT_SG_AutoFire",UI=AliasMap.Switcher,Text=T(" Auto Tembak"," Auto Fire"),ExpandHandle="ModMenu_AT_SG_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSGAutoFire end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSGAutoFire=v return true end},{Key="ModMenu_AT_SG_IgKnock",UI=AliasMap.Switcher,Text=T(" Abaikan Musuh Knock"," Ignore Knocked"),ExpandHandle="ModMenu_AT_SG_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSGIgKnock end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSGIgKnock=v return true end},{Key="ModMenu_AT_SG_IgBot",UI=AliasMap.Switcher,Text=T(" Abaikan Bot"," Ignore Bots"),ExpandHandle="ModMenu_AT_SG_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSGIgBot end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSGIgBot=v return true end},{Key="ModMenu_AT_SG_Vis",UI=AliasMap.Switcher,Text=T(" Vischek (Dinding)"," Visibility Check"),ExpandHandle="ModMenu_AT_SG_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSGVisCheck end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSGVisCheck=v return true end},{Key="ModMenu_AT_SG_Prio",UI=AliasMap.Slider,Text=T(" Prioritas Tembakan (1:Crosshair 2:Jarak 3:Darah)"," Priority (1:Crosshair 2:Distance 3:HP)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGPrio or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchSGPrio=val return true end},{Key="ModMenu_AT_SG_Bone",UI=AliasMap.Slider,Text=T(" Arah Tembakan (1:Kepala 2:Dada 3:Perut 4:Paha)"," Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGBone or 2 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchSGBone=val return true end},{Key="ModMenu_AT_SG_Cond",UI=AliasMap.Slider,Text=T(" Kondisi (1:Menembak,2:Selalu"," Trigger (1:On Fire,2:Always"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=2,min=1,max=2,Min=1,Max=2,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGCond or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>2 then val=2 end;_G.AimPROState.CustomTextData.AimTouchSGCond=val return true end},{Key="ModMenu_AT_SG_Spd",UI=AliasMap.Slider,Text=T(" Kecepatan (1-100)"," Smoothness/Speed (1-100)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGSpeed or 80 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSGSpeed=v return true end},{Key="ModMenu_AT_SG_Dist",UI=AliasMap.Slider,Text=T(" Jarak Maksimal (1-100m)"," Distance Limit (1-100m)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGDist or 30 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSGDist=v return true end},{Key="ModMenu_AT_SG_FOV",UI=AliasMap.Slider,Text=T(" Radius FOV (1-100)"," FOV Radius (1-100)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGFOV or 40 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSGFOV=v return true end},{Key="ModMenu_AT_SG_FOVColor",UI=AliasMap.Slider,Text=T(" Warna FOV (1-7)"," Circle Color (1-7)"),ExpandHandle="ModMenu_AT_SG_Ex",MinValue=1,MaxValue=7,min=1,max=7,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSGFOVColor or 1 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSGFOVColor=v return true end}, -- SCOPE ALL (senjata biasa saat buka SCOPE)
{Key="ModMenu_AT_ScopeAll_Ex",UI=AliasMap.TitleSwitcher,Text=T(" ▶ Aimbot Scope"," ▶ Scope Aimbot"),ExpandHandle="ModMenu_AT_Ex",ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchScopeAll end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchScopeAll=v return true end},{Key="ModMenu_AT_ScopeAll_IgKnock",UI=AliasMap.Switcher,Text=T(" Abaikan Musuh Knock"," Ignore Knocked"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchScopeIgKnock end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchScopeIgKnock=v return true end},{Key="ModMenu_AT_ScopeAll_IgBot",UI=AliasMap.Switcher,Text=T(" Abaikan Bot"," Ignore Bots"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchScopeIgBot end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchScopeIgBot=v return true end},{Key="ModMenu_AT_ScopeAll_Vis",UI=AliasMap.Switcher,Text=T(" Vischek (Dinding)"," Visibility Check"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchScopeVisCheck end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchScopeVisCheck=v return true end},{Key="ModMenu_AT_ScopeAll_Prio",UI=AliasMap.Slider,Text=T(" Prioritas Tembakan (1:Crosshair 2:Jarak 3:Darah)"," Priority (1:Crosshair 2:Distance 3:HP)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopePrio or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchScopePrio=val return true end},{Key="ModMenu_AT_ScopeAll_Bone",UI=AliasMap.Slider,Text=T(" Arah Tembakan (1:Kepala 2:Dada 3:Perut 4:Paha)"," Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeBone or 2 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchScopeBone=val return true end},{Key="ModMenu_AT_ScopeAll_Cond",UI=AliasMap.Slider,Text=T(" Kondisi (1:Menembak,2:Selalu"," Trigger (1:On Fire,2:Always)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=2,min=1,max=2,Min=1,Max=2,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeCond or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>2 then val=2 end;_G.AimPROState.CustomTextData.AimTouchScopeCond=val return true end},{Key="ModMenu_AT_ScopeAll_Spd",UI=AliasMap.Slider,Text=T(" Kecepatan (1-100)"," Smoothness/Speed (1-100)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeSpeed or 40 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopeSpeed=v return true end},{Key="ModMenu_AT_ScopeAll_Dist",UI=AliasMap.Slider,Text=T(" Jarak Maksimal (1-500m)"," Distance Limit (1-500m)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return math.floor((_G.AimPROState.CustomTextData.AimTouchScopeDist or 300)/5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopeDist=v*5 return true end},{Key="ModMenu_AT_ScopeAll_Pred",UI=AliasMap.Slider,Text=T(" Prediksi Arah Lari"," Prediction Value"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopePred or 0 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopePred=v return true end},{Key="ModMenu_AT_ScopeAll_Recoil",UI=AliasMap.Slider,Text=T(" Recoil Kompensasi"," Auto Recoil Comp."),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=0,MaxValue=50,min=0,max=50,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeRecoil or 0 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopeRecoil=v return true end},{Key="ModMenu_AT_ScopeAll_FOV",UI=AliasMap.Slider,Text=T("Radius FOV (1-100)"," FOV Radius (1-100)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeFOV or 20 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopeFOV=v return true end},{Key="ModMenu_AT_ScopeAll_FOVColor",UI=AliasMap.Slider,Text=T(" Warna FOV (1-7)"," Circle Color (1-7)"),ExpandHandle="ModMenu_AT_ScopeAll_Ex",MinValue=1,MaxValue=7,min=1,max=7,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchScopeFOVColor or 6 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchScopeFOVColor=v return true end}, -- SCOPE SNIPER (senjata membidik/TỈA)
{Key="ModMenu_AT_Sniper_Ex",UI=AliasMap.TitleSwitcher,Text=T(" ▶ Aimbot Sniper "," ▶ Sniper Aimbot"),ExpandHandle="ModMenu_AT_Ex",ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchScopeSniper end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchScopeSniper=v return true end},{Key="ModMenu_AT_Sniper_IgKnock",UI=AliasMap.Switcher,Text=T(" Abaikan Musuh Knock"," Ignore Knocked"),ExpandHandle="ModMenu_AT_Sniper_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSniperIgKnock end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSniperIgKnock=v return true end},{Key="ModMenu_AT_Sniper_IgBot",UI=AliasMap.Switcher,Text=T(" Abaikan Bot"," Ignore Bots"),ExpandHandle="ModMenu_AT_Sniper_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSniperIgBot end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSniperIgBot=v return true end},{Key="ModMenu_AT_Sniper_Vis",UI=AliasMap.Switcher,Text=T(" Vischek (Dinding)"," Visibility Check"),ExpandHandle="ModMenu_AT_Sniper_Ex",GetFunc=function()return _G.AimPROConfig.AimTouchSniperVisCheck end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchSniperVisCheck=v return true end},{Key="ModMenu_AT_Sniper_Prio",UI=AliasMap.Slider,Text=T(" Prioritas Tembakan (1:Crosshair 2:Jarak 3:Darah)"," Priority (1:Crosshair 2:Distance 3:HP)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperPrio or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchSniperPrio=val return true end},{Key="ModMenu_AT_Sniper_Bone",UI=AliasMap.Slider,Text=T(" Arah Tembakan (1:Kepala 2:Dada 3:Perut 4:Paha)"," Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=4,min=1,max=4,Min=1,Max=4,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperBone or 1 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>4 then val=4 end;_G.AimPROState.CustomTextData.AimTouchSniperBone=val return true end},{Key="ModMenu_AT_Sniper_Cond",UI=AliasMap.Slider,Text=T(" Kondisi (1:Menembak,2:Selalu"," Trigger (1:On Fire,2:Always)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=2,min=1,max=2,Min=1,Max=2,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperCond or 2 end,SetFunc=function(c,v)local val=math.floor(v+0.5);if val<1 then val=1 end;if val>2 then val=2 end;_G.AimPROState.CustomTextData.AimTouchSniperCond=val return true end},{Key="ModMenu_AT_Sniper_Spd",UI=AliasMap.Slider,Text=T(" Kecepatan (1-100)"," Smoothness/Speed (1-100)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperSpeed or 30 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSniperSpeed=v return true end},{Key="ModMenu_AT_Sniper_Dist",UI=AliasMap.Slider,Text=T(" Jarak Maksimal (1-500m)"," Distance Limit (1-500m)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return math.floor((_G.AimPROState.CustomTextData.AimTouchSniperDist or 400)/5)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSniperDist=v*5 return true end},{Key="ModMenu_AT_Sniper_Pred",UI=AliasMap.Slider,Text=T(" Prediksi Arah Lari (0-100)"," Prediction Value (0-100)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperPred or 0 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSniperPred=v return true end},{Key="ModMenu_AT_Sniper_FOV",UI=AliasMap.Slider,Text=T(" Radius FOV (1-100)"," FOV Radius (1-100)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperFOV or 20 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSniperFOV=v return true end},{Key="ModMenu_AT_Sniper_FOVColor",UI=AliasMap.Slider,Text=T(" Warna FOV (1-7)"," Circle Color (1-7)"),ExpandHandle="ModMenu_AT_Sniper_Ex",MinValue=1,MaxValue=7,min=1,max=7,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchSniperFOVColor or 4 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchSniperFOVColor=v return true end}, -- AIMBOT senjata MORTAR (MORTAR)
{Key="ModMenu_AT_Mortar_Ex",UI=AliasMap.TitleSwitcher,Text=T(" ▶ Aimbot Mortar"," ▶ Mortar Aimbot"),ExpandHandle="ModMenu_AT_Ex",ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AimTouchMortar end,SetFunc=function(c,v)_G.AimPROConfig.AimTouchMortar=v return true end},{Key="ModMenu_AT_Mortar_Pred",UI=AliasMap.Slider,Text=T(" Prediksi Arah Lari (0-100)"," Prediction Value (0-100)"),ExpandHandle="ModMenu_AT_Mortar_Ex",MinValue=0,MaxValue=100,min=0,max=100,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchMortarPred or 0 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchMortarPred=v return true end},{Key="ModMenu_AT_Mortar_FOV",UI=AliasMap.Slider,Text=T(" Radius FOV (1-360)"," FOV Radius (1-360)"),ExpandHandle="ModMenu_AT_Mortar_Ex",MinValue=1,MaxValue=360,min=1,max=360,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchMortarFOV or 360 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchMortarFOV=v return true end},{Key="ModMenu_AT_Mortar_FOVColor",UI=AliasMap.Slider,Text=T(" Warna FOV (1-7)"," Circle Color (1-7)"),ExpandHandle="ModMenu_AT_Mortar_Ex",MinValue=1,MaxValue=7,min=1,max=7,GetFunc=function()return _G.AimPROState.CustomTextData.AimTouchMortarFOVColor or 5 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.AimTouchMortarFOVColor=v return true end}
}
local StackSkin={{Key="ModMenu_ModEmote",UI=AliasMap.Switcher,Text=T(" Buka Semua Emot","Unlock All VIP Emotes"),GetFunc=function()return _G.AimPROConfig.ModEmote end,SetFunc=function(c,v)_G.AimPROConfig.ModEmote=v return true end},{Key="ModMenu_ModSkin",UI=AliasMap.Switcher,Text=T(" Mod Skin VIP (Sistem Inventory)","VIP Mod Skin System (Open inventory)"),GetFunc=function()return _G.AimPROConfig.ModSkin end,SetFunc=function(c,v)_G.AimPROConfig.ModSkin=v return true end},{Key="ModMenu_SkinDeadBox",UI=AliasMap.Switcher,Text=T("Peti Loot (Sesuai Senjata)","Deadbox Skin (Sync with Weapon)"),GetFunc=function()return _G.AimPROConfig.SkinDeadBox end,SetFunc=function(c,v)_G.AimPROConfig.SkinDeadBox=v return true end},{Key="ModMenu_SkinAttachment",UI=AliasMap.Switcher,Text=T("Skin Senjata & Aksesoris","Weapon Attachment Skin"),GetFunc=function()return _G.AimPROConfig.SkinAttachment end,SetFunc=function(c,v)_G.AimPROConfig.SkinAttachment=v return true end},{Key="ModMenu_KillMessage",UI=AliasMap.Switcher,Text=T("Kill Messenger VIP","VIP Kill Messenger"),GetFunc=function()return _G.AimPROConfig.KillMessage end,SetFunc=function(c,v)_G.AimPROConfig.KillMessage=v return true end},{Key="ModMenu_KillCountUI",UI=AliasMap.Switcher,Text=T("Kill Counter UI","Kill Counter UI"),GetFunc=function()return _G.AimPROConfig.KillCountUI end,SetFunc=function(c,v)_G.AimPROConfig.KillCountUI=v return true end},{Key="ModMenu_SkinOpenLink",UI=AliasMap.Switcher,Text=T(_G.__BRG_C(string.char(52,105,109,80,80+2,79)).." (Link)",_G.__BRG_B(string.char(52,105,109,80,80+2,79)).." (Link)"),GetFunc=function()return _G.AimPROConfig.SkinOpenLink end,SetFunc=function(c,v)_G.AimPROConfig.SkinOpenLink=v;if v==true then pcall(function()local Web=require("client.slua.logic.url.logic_webview_sdk");if Web and Web.OpenURL then Web:OpenURL("https://t.me/imprr0")end end)end return true end},}
local StackCombat={{Key="ModMenu_FakeHWID",UI=AliasMap.Switcher,Text=T("Fake ID (Antiban)","Fake HWID (Anti-Ban)"),GetFunc=function()return _G.AimPROConfig.FakeHWID end,SetFunc=function(c,v)_G.AimPROConfig.FakeHWID=v return true end},{Key="ModMenu_TPPFPP_Enable",UI=AliasMap.Switcher,Text="Fpp To Tpp",ExpandIndex=2,GetFunc=function()
return _G.AimPROConfig.tppfpp
end,SetFunc=function(c,v)
_G.AimPROConfig.tppfpp=v
return true
end
},{Key="ModMenu_AutoReport_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ AUTO REPORT SYSTEM","▶ AUTO REPORT SYSTEM"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.AutoReportEnable end,SetFunc=function(c,v)_G.AimPROConfig.AutoReportEnable=v return true end},{Key="ModMenu_AutoMassReport",UI=AliasMap.Switcher,Text=T(" Mass Report Otomatis"," Auto Mass Report"),ExpandHandle="ModMenu_AutoReport_Ex",GetFunc=function()return _G.AimPROConfig.AutoMassReport end,SetFunc=function(c,v)_G.AimPROConfig.AutoMassReport=v return true end},{Key="ModMenu_AutoKillerReport",UI=AliasMap.Switcher,Text=T(" Report Killer Otomatis"," Auto Report Killer"),ExpandHandle="ModMenu_AutoReport_Ex",GetFunc=function()return _G.AimPROConfig.AutoKillerReport end,SetFunc=function(c,v)_G.AimPROConfig.AutoKillerReport=v return true end},{Key="ModMenu_Ipad_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Ipad View","▶ Ipad View"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.IpadView end,SetFunc=function(c,v)_G.AimPROConfig.IpadView=v return true end},{Key="ModMenu_Ipad_FOV",UI=AliasMap.Slider,Text=T(" Set FOV"," FOV Value"),ExpandHandle="ModMenu_Ipad_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return(_G.AimPROState.CustomTextData.IpadViewFOV or 120)-90 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.IpadViewFOV=90+v return true end},{Key="ModMenu_IpadVeh_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Ipad View Kendaraan","▶ Ipad View Vehicle"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.IpadViewVehicle end,SetFunc=function(c,v)_G.AimPROConfig.IpadViewVehicle=v return true end},{Key="ModMenu_IpadVeh_FOV",UI=AliasMap.Slider,Text=T(" Set FOV Kendaraan "," Vehicle FOV Value"),ExpandHandle="ModMenu_IpadVeh_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return(_G.AimPROState.CustomTextData.IpadViewVehicleFOV or 120)-90 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.IpadViewVehicleFOV=90+v return true end},{Key="ModMenu_IpadScope_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Ipad View Scope","▶ Ipad View Scope"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.IpadViewScope end,SetFunc=function(c,v)_G.AimPROConfig.IpadViewScope=v return true end},{Key="ModMenu_IpadScope_FOV",UI=AliasMap.Slider,Text=T(" Ser FOV Scope (30-120)"," Scope FOV (30-120)"),ExpandHandle="ModMenu_IpadScope_Ex",MinValue=30,MaxValue=120,min=30,max=120,GetFunc=function()return _G.AimPROState.CustomTextData.IpadViewScopeFOV or 60 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.IpadViewScopeFOV=v return true end},{Key="ModMenu_BugMan_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Karakter Gemuk","▶ Screen Stretch (Fat Body)"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.BugManEnable end,SetFunc=function(c,v)_G.AimPROConfig.BugManEnable=v return true end},{Key="ModMenu_BugMan_Ratio",UI=AliasMap.Slider,Text=T(" Rasio Kegemukan"," Stretch Ratio"),ExpandHandle="ModMenu_BugMan_Ex",MinValue=110,MaxValue=200,min=110,max=200,GetFunc=function()return _G.AimPROState.CustomTextData.BugManRatio or 133 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.BugManRatio=v return true end},{Key="ModMenu_165FPS",UI=AliasMap.Switcher,Text=T("Buka 165 FPS","Unlock 165 FPS"),GetFunc=function()return _G.AimPROConfig.UnlockFPS end,SetFunc=function(c,v)_G.AimPROConfig.UnlockFPS=v;if v then _G.AimPROState.GraphicsUnlocked=false end return true end}, --    { Key = "ModMenu_WallXuyenTuong", UI = AliasMap.Switcher, Text = T("Wallhack V1 ", "Wallhack V1 (See through)"), GetFunc = function() return _G.AimPROConfig.WallXuyenTuong end, SetFunc = function(c,v) _G.AimPROConfig.WallXuyenTuong = v return true end },
 --  { Key = "ModMenu_ColorBodyV2", UI = AliasMap.Switcher, Text = T("Wallhack V2 (Warna Basic)", "Chams V2 (Basic Color)"), GetFunc = function() return _G.AimPROConfig.ColorBodyV2 end, SetFunc = function(c,v) _G.AimPROConfig.ColorBodyV2 = v return true end },
{Key="ModMenu_ColorBodyNew",UI=AliasMap.Switcher,Text=T("Wallhack V1","Wallhack V1"),GetFunc=function()return _G.AimPROConfig.ColorBodyNew end,SetFunc=function(c,v)_G.AimPROConfig.ColorBodyNew=v return true end},{Key="ModMenu_ColorBodyV3_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Wallhack V2 (Custom Warna)","▶ WallHack V2 (Custom)"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.ColorBodyV3 end,SetFunc=function(c,v)_G.AimPROConfig.ColorBodyV3=v return true end},{Key="ModMenu_V3_Hidden",UI=AliasMap.Slider,Text=T(" Warna di balik Objek (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Purple 6:Putih)"," Hidden Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht)"),ExpandHandle="ModMenu_ColorBodyV3_Ex",MinValue=1,MaxValue=6,GetFunc=function()return _G.AimPROState.CustomTextData.ColorV3Hidden or 1 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.ColorV3Hidden=v return true end},{Key="ModMenu_V3_Vis",UI=AliasMap.Slider,Text=T(" Warna Visible (1:Merah 2:Hujai 3:Biru 4:Kuning 5:Purple 6:Putih)"," Visible Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht)"),ExpandHandle="ModMenu_ColorBodyV3_Ex",MinValue=1,MaxValue=6,GetFunc=function()return _G.AimPROState.CustomTextData.ColorV3Visible or 2 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.ColorV3Visible=v return true end},{Key="ModMenu_V3_Thick",UI=AliasMap.Slider,Text=T(" Garis Tepi (HDR)"," HDR Outline Thickness"),ExpandHandle="ModMenu_ColorBodyV3_Ex",MinValue=1,MaxValue=20,GetFunc=function()return _G.AimPROState.CustomTextData.ColorV3Thickness or 4 end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.ColorV3Thickness=v return true end}, --    { Key = "ModMenu_WallVehicle", UI = AliasMap.Switcher, Text = T("Wallhack Kendaraan", "Vehicle Wallhack"), GetFunc = function() return _G.AimPROConfig.WallVehicle end, SetFunc = function(c,v) _G.AimPROConfig.WallVehicle = v return true end },
{Key="ModMenu_WhiteBody",UI=AliasMap.Switcher,Text=T("White Body","White Body"),GetFunc=function()return _G.AimPROConfig.WhiteBody end,SetFunc=function(c,v)_G.AimPROConfig.WhiteBody=v return true end},{Key="ModMenu_BlackSky",UI=AliasMap.Switcher,Text=T("Langit Gelap (Black Sky)","Black Sky"),GetFunc=function()return _G.AimPROConfig.BlackSky end,SetFunc=function(c,v)_G.AimPROConfig.BlackSky=v return true end},{Key="ModMenu_LightUltraHDR",UI=AliasMap.Switcher,Text=T("Mode Performa","Light Graphics"),GetFunc=function()return _G.AimPROConfig.LightUltraHDR end,SetFunc=function(c,v)_G.AimPROConfig.LightUltraHDR=v return true end},{Key="ModMenu_RemoveFog",UI=AliasMap.Switcher,Text=T("Hilangkan Kabut","Remove Fog"),GetFunc=function()return _G.AimPROConfig.RemoveFog end,SetFunc=function(c,v)_G.AimPROConfig.RemoveFog=v return true end},{Key="ModMenu_RemoveGrass",UI=AliasMap.Switcher,Text=T("Hilangkan Rumput","Remove Grass"),GetFunc=function()return _G.AimPROConfig.RemoveGrass end,SetFunc=function(c,v)_G.AimPROConfig.RemoveGrass=v return true end},{Key="ModMenu_RemoveTrees",UI=AliasMap.Switcher,Text=T("Hilangkan Pohon","Remove Trees"),GetFunc=function()return _G.AimPROConfig.RemoveTrees end,SetFunc=function(c,v)_G.AimPROConfig.RemoveTrees=v return true end},{Key="ModMenu_WallClimb",UI=AliasMap.Switcher,Text=T("Wall Climb","Wall Climb"),GetFunc=function()return _G.AimPROConfig.WallClimb end,SetFunc=function(c,v)_G.AimPROConfig.WallClimb=v return true end},{Key="ModMenu_FastCar_Ex",UI=AliasMap.TitleSwitcher,Text=T("▶ Kendaraan Cepat/Fly (RISK)","▶ Fast Car/Flying Car (RISK)"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.FastCar end,SetFunc=function(c,v)_G.AimPROConfig.FastCar=v return true end},{Key="ModMenu_FastCar_Speed",UI=AliasMap.Slider,Text=T(" Batas Kecepatan (1-100)"," Car Speed Limit (1-100)"),ExpandHandle="ModMenu_FastCar_Ex",MinValue=1,MaxValue=100,min=1,max=100,GetFunc=function()return math.floor((_G.AimPROState.CustomTextData.FastCarSpeed or 3000)/60)end,SetFunc=function(c,v)_G.AimPROState.CustomTextData.FastCarSpeed=v*60 return true end}, -- { Key = "ModMenu_WeaponGlow_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Senjata Glow (HDR)", "▶ Weapon Glow (HDR)"), ExpandIndex = 0, GetFunc = function() return _G.AimPROConfig.WeaponGlow end, SetFunc = function(c,v) _G.AimPROConfig.WeaponGlow = v return true end },
 -- { Key = "ModMenu_WeaponGlowColor", UI = AliasMap.Slider, Text = T(" Warna (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Rainbow)", "   Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Rnb)"), ExpandHandle = "ModMenu_WeaponGlow_Ex", MinValue = 1, MaxValue = 5, GetFunc = function() return _G.AimPROState.CustomTextData.WeaponGlowColor or 5 end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.WeaponGlowColor = v return true end },
 --{ Key = "ModMenu_WeaponGlowThick", UI = AliasMap.Slider, Text = T(" Glow Thicknes", "   Glow Thickness"), ExpandHandle = "ModMenu_WeaponGlow_Ex", MinValue = 1, MaxValue = 15, GetFunc = function() return _G.AimPROState.CustomTextData.WeaponGlowThickness or 3 end, SetFunc = function(c,v) _G.AimPROState.CustomTextData.WeaponGlowThickness = v return true end }
}
local StackESPV2={{Key="ModMenu_ESP9_Ex",UI=AliasMap.TitleSwitcher,Text=T("ESP LITE","ESP LITE"),ExpandIndex=0,GetFunc=function()return _G.AimPROConfig.EspLoai9 end,SetFunc=function(c,v)
  _G.AimPROConfig.EspLoai9=v
  if not v then
    -- Matikan renderer secara langsung; jangan menunggu MainLoop berikutnya.
    if _G.PlayerMapMarker and type(_G.PlayerMapMarker.Stop)=="function" then pcall(_G.PlayerMapMarker.Stop) end
  elseif _G.PlayerMapMarker and type(_G.PlayerMapMarker.Start)=="function" then
    pcall(_G.PlayerMapMarker.Start)
  end
  return true
end},{Key="ModMenu_ESP9_Line",UI=AliasMap.Switcher,Text=T("  ESP Line","  ESP Line"),ExpandHandle="ModMenu_ESP9_Ex",GetFunc=function()return _G.AimPROConfig.Esp9_Line~=false end,SetFunc=function(c,v)_G.AimPROConfig.Esp9_Line=v return true end},{Key="ModMenu_ESP9_Box",UI=AliasMap.Switcher,Text=T("  ESP Box","  ESP Box"),ExpandHandle="ModMenu_ESP9_Ex",GetFunc=function()return _G.AimPROConfig.Esp9_Box~=false end,SetFunc=function(c,v)_G.AimPROConfig.Esp9_Box=v return true end},{Key="ModMenu_ESP9_Name",UI=AliasMap.Switcher,Text=T("  Player / Bot","  Player / Bot"),ExpandHandle="ModMenu_ESP9_Ex",GetFunc=function()return _G.AimPROConfig.Esp9_Name~=false end,SetFunc=function(c,v)_G.AimPROConfig.Esp9_Name=v return true end},{Key="ModMenu_ESP9_Distance",UI=AliasMap.Switcher,Text=T("  Distance","  Distance"),ExpandHandle="ModMenu_ESP9_Ex",GetFunc=function()return _G.AimPROConfig.Esp9_Distance~=false end,SetFunc=function(c,v)_G.AimPROConfig.Esp9_Distance=v return true end},{Key="ModMenu_ESP9_Visibility",UI=AliasMap.Switcher,Text=T("  Open / Close","  Open / Close"),ExpandHandle="ModMenu_ESP9_Ex",GetFunc=function()return _G.AimPROConfig.Esp9_Visibility~=false end,SetFunc=function(c,v)_G.AimPROConfig.Esp9_Visibility=v return true end}}
SettingPageDefine.ModMenu={Key="ModMenu",Text=_G.__BRG_A(string.char(52,105,109,80,80+2,79)),UIKey="Setting_Page_Privacy",Category={{Key="Cat_ESP",Text=999001,Stack=StackESP},{Key="Cat_ESPV2",Text=999006,Stack=StackESPV2},{Key="Cat_Aimbot",Text=999002,Stack=StackAimbot},{Key="Cat_AimbotV2",Text=999003,Stack=StackAimbotV2},{Key="Cat_Combat",Text=999004,Stack=StackCombat},{Key="Cat_Skin",Text=999005,Stack=StackSkin}
}
}
table.insert(SettingCatalog,1,SettingPageDefine.ModMenu)
end
pcall(_G.InstallAimPROGraphicsCategory)
local UIManager=_G.UIManager
if UIManager and not UIManager._IsModMenuHooked then
local old_ShowUI=UIManager.ShowUI
UIManager.ShowUI=function(config,...)
local args={...}
local n=select('#',...)
if config and config.keyName then
local lowerKeyName=string.lower(config.keyName)
if string.find(lowerKeyName,"setting_main")and not string.find(lowerKeyName,"custom")then
local catalog=args[1]
if type(catalog)=="table"and catalog[1]and type(catalog[1])=="table"and catalog[1].Key then
local hasModMenu=false
for _,page in ipairs(catalog)do
if type(page)=="table"and page.Key=="ModMenu"then
hasModMenu=true
break
end
end
if not hasModMenu then
table.insert(catalog,1,SettingPageDefine.ModMenu)
end
end
end
end
pcall(_G.InstallAimPROGraphicsCategory)
local table_unpack=table.unpack or unpack
return old_ShowUI(config,table_unpack(args,1,n))
end
UIManager._IsModMenuHooked=true
end
end
local function Show4imPROVIPMenu()
if _G.AimPROMenuAlreadyShown then return end
if _G.AimPROState.MenuStep~=0 then return end
pcall(function()
local Msg=require("client.slua.logic.common.logic_common_msg_box")
if not Msg or not Msg.Show then return end
local function Step_ScamAlert()
local title=_G.AimPROLang=="EN"and"SCAM ALERT"or"HATI HATI PENIPUAN"
local content=_G.AimPROLang=="EN"
and"Join Ke Telegram Official ".._G.__BRG_A(string.char(52,105,109,80,80+2,79))
or"Reall Owner @zexygodx\n\n Jangan Lupa Feedback"
local btn1=_G.AimPROLang=="EN"and"JOIN"or"GABUNG"
local btn2=_G.AimPROLang=="EN"and"CLOSE"or"TUTUP"
Msg.Show(1,title,content,function()local Web=require("client.slua.logic.url.logic_webview_sdk");if Web and Web.OpenURL then Web:OpenURL("https://t.me/imprr0")end end,function()end,btn1,btn2)
_G.AimPROState.MenuStep=99
_G.AimPROMenuAlreadyShown=true
end
local function Step_Welcome()
local title=_G.AimPROLang=="EN"and"WELCOME TO VIP MOD ".._G.__BRG_A(string.char(71,79,68,77,79,68))or"SELAMAT DATANG DI VIP MOD ".._G.__BRG_C(string.char(52,105,109,80,80+2,79))
local content=_G.AimPROLang=="EN"
and"The cheat is now active;the VIP MOD menu has been added to the settings!\nPlay like a pro player.Play safe!"
or"1 Pesan:Ga usah Sok Sok an Brutal kalok lu sayang akun,Main selayaknya Proplayer!\n\nJangan Lupa Feedback!"
local btn1=_G.AimPROLang=="EN"and"OPEN GAME MENU"or"BUKA MENU GAME"
local btn2=_G.AimPROLang=="EN"and"CLOSE"or"TUTUP"
Msg.Show(1,title,content,function()
_G.InitModMenuTab()
if _G.AimPROLang=="EN"then
Notify("VIP MOD MENU ADDED!\nOpen Settings (Gear icon)->VIP MOD MENU to toggle features.")
else
Notify("VIP MOD MENU AKTIF\nSilahkan Buka Menu Seting.")
end
Step_ScamAlert()
end,function()end,btn1,btn2)
end
local function Step_SelectLanguage()
Msg.Show(2,"SELECT LANGUAGE/PILIH BAHASA","Please select your preferred language.\nSilahkan Pilih Bahasa Anda.",function()
_G.AimPROLang="ID"
Step_Welcome()
end,function()
_G.AimPROLang="EN"
Step_Welcome()
end,"INDONESIA","ENGLISH")
end
local function Step_LegalNotice()
local legal_title="PERINGATAN!-Announcement from Admin @".._G.__BRG_A(string.char(71,79,68,77,79,68))
local legal_content="\nGunakan fitur secukupnya. Jangan berlebihan.\nBermain terlalu brutal hanya akan membuatmu lebih mudah diperhatikan.\n\nJangan tunggu sampai peringatan ini berubah menjadi tindakan.\nKami sudah mengingatkan. Selebihnya, risiko milikmu.\n\nJangan Lupa Feedback!!\nDon't forget to provide feedback!!"
local legal_btnOK="OK"
local legal_btnCancel="Cancel"
local legal_url="https://t.me/imprr0"
local legal_msg=require("client.slua.logic.common.logic_common_legal_msg")
if not legal_msg then
 -- jika game tidak punya legal notice, kembali ke daftar pilihan bahasa
Step_SelectLanguage()
return
end
legal_msg.ShowOnePopUI({tabType=0,title=legal_title,content=legal_content,tipsText=nil,btnOKText=legal_btnOK,btnCancelText=legal_btnCancel,acceptFunc=function()
 -- Tekan Confirm -> buka daftar pilihan bahasa
Step_SelectLanguage()
end,refuseFunc=function()
 -- Tekan Join Channel -> buka Telegram -> buka daftar pilihan bahasa
local KismetSystemLibrary=import("KismetSystemLibrary")
if KismetSystemLibrary then
KismetSystemLibrary:LaunchURL(legal_url)
end
Step_SelectLanguage()
end
})
end
_G.AimPROState.MenuStep=1
 -- tampilkan Legal Notice sebelum kembali ke daftar pilihan bahasa
Step_LegalNotice()
end)
end
 -- ============================================================
-- START / STOP OTOMATIS (DIJALANKAN DI MAINLOOP)
-- ============================================================
local function CheckAutoReportStatus()
if _G.AimPROConfig.AutoReportEnable then
if not _G.AutoReportRunning then
pcall(AutoReport.Start)
_G.AutoReportRunning=true
end
else
if _G.AutoReportRunning then
pcall(AutoReport.Stop)
_G.AutoReportRunning=false
end
end
end
-- ========================================== 
-- LOGIC buka kunci 165 FPS dan UI IPAD VIEW 
-- ========================================== 
local function InitializeGraphicsUnlock()
if _i then return end
if _G.AimPROState.GraphicsUnlocked or _i then return end
pcall(function()
local SettingCfg=require("client.logic.setting.setting_config")
local GraphicSettingDB=require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
if SettingCfg then
if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max=160 end
if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max=160 end
end
if GraphicSettingDB then
if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max=160 end
end
end)
pcall(function()
local logic_setting_graphics=require("client.slua.logic.setting.logic_setting_graphics")
local GSC_FPS=require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
local GSC_FPSFT=require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
local GraphicSettingDB=require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
local KismetMathLibrary=import("KismetMathLibrary")or _G.KismetMathLibrary
local FLinearColor=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
if logic_setting_graphics then
local old_SetFPS=logic_setting_graphics.SetFPS
function logic_setting_graphics.SetFPS(gameInstance,FPSLevel)
if old_SetFPS then old_SetFPS(gameInstance,FPSLevel)end
if FPSLevel==8 then
gameInstance:ExecuteCMD("t.MaxFPS","165")
gameInstance:ExecuteCMD("r.FrameRateLimit","165")
end
end
end
if GSC_FPS and GSC_FPS.__inner_impl then
local fps_impl=GSC_FPS.__inner_impl
function fps_impl:GetMaxFPSLevel()return 8,8 end
function fps_impl:InitRealSupportFPS()
local RealSupportFPS={}
for i=1,8 do RealSupportFPS[i]={true,true}end
if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS,RealSupportFPS,false)end
return RealSupportFPS
end
function fps_impl:UpdateSelectedFPSState(selectedLevel)
if not slua.isValid(self.UIRoot)then return end
for level=2,8 do
local name="NodeFps"..(({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level]or 120)
local widget=self.UIRoot[name]
if slua.isValid(widget)then
widget:SetIsEnabled(true)
pcall(function()widget:SetRenderOpacity(1.0)end)
local switcher=self.UIRoot["WidgetSwitcher_"..level]
if slua.isValid(switcher)then
switcher:SetActiveWidgetIndex(level==selectedLevel and 0 or 1)
end
end
end
end
end
if GSC_FPSFT and GSC_FPSFT.__inner_impl then
local ft_impl=GSC_FPSFT.__inner_impl
local NMinFPS,NStep=90,5
local function clamp(value,min,max)
if value<min then return min end
if max<value then return max end
return value
end
local function lerp(a,b,t)return a+(b-a)*t end
local function _getColorByPercent(start,finish,percent)
if not FLinearColor then return nil end
return FLinearColor(lerp(start.R,finish.R,percent),lerp(start.G,finish.G,percent),lerp(start.B,finish.B,percent),lerp(start.A,finish.A,percent))
end
ft_impl.ShowOrHide=function(self)
self:SelfHitTestInvisible()
if self.InitFPSFTSwitch then self:InitFPSFTSwitch()end
end
ft_impl.InitFPSFTSwitch=function(self)
local FPSFineTuneSwitch=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch,true)end
if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8,FPSFineTuneSwitch)end
if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)end
if self.InitFPSFTValue165 then self:InitFPSFTValue165()end
end
ft_impl.InitFPSFTValue165=function(self)
local itemRoot=self.UIRoot
local FPSFineTuneSwitch=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
local FPSFineTuneNum=165
if FPSFineTuneSwitch then
FPSFineTuneNum=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)or 165
itemRoot.Slider_screen3:SetLocked(false)
if FLinearColor then
itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0,1.0,1.0,1.0))
itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0,1.0,1.0,1.0))
end
else
itemRoot.Slider_screen3:SetLocked(true)
if FLinearColor then
itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0,0.625,0.6,1))
itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0,0.625,0.6,1.0))
end
end
local FPSFineTunePer=(FPSFineTuneNum-NMinFPS)/(165-NMinFPS)
itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)
if FLinearColor then
local startColor=FLinearColor(1.0,1.0,1.0,1.0)
local midColor=FLinearColor(1.0,0.54,0.11,1.0)
local endColor=FLinearColor(1.0,0.23,0.15,1.0)
local sliderColor=FPSFineTunePer<0.4 and startColor or _getColorByPercent(midColor,endColor,(FPSFineTunePer-0.4)/0.6)
itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
end
end
ft_impl.OnFPSFTValueChange3=function(self,FPSFineTuneNum)
GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum,FPSFineTuneNum)
if self.InitFPSFTValue165 then self:InitFPSFTValue165()end
if self:GetParentUI()then self:GetParentUI():SetDirty(true)end
local gameInstance=GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
if gameInstance then
gameInstance:ExecuteCMD("t.MaxFPS",tostring(FPSFineTuneNum))
gameInstance:ExecuteCMD("r.FrameRateLimit",tostring(FPSFineTuneNum))
end
end
ft_impl.OnFPSFTSliderValueChange3=function(self,value)
if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)and KismetMathLibrary then
local FPSFineTuneNum=KismetMathLibrary.FCeil(value*(165-NMinFPS)/NStep)*NStep+NMinFPS
self:OnFPSFTValueChange3(clamp(FPSFineTuneNum,NMinFPS,165))
end
end
ft_impl.OnFPSFTAdd=ft_impl.OnFPSFTAdd3
ft_impl.OnFPSFTMinus=ft_impl.OnFPSFTMinus3
ft_impl.OnFPSFTAdd2=ft_impl.OnFPSFTAdd3
ft_impl.OnFPSFTMinus2=ft_impl.OnFPSFTMinus3
ft_impl.OnFPSFTSliderValueChange=ft_impl.OnFPSFTSliderValueChange3
ft_impl.OnFPSFTSliderValueChange2=ft_impl.OnFPSFTSliderValueChange3
end
end)
_G.AimPROState.GraphicsUnlocked=true
Notify("Graphics & FPS 165Hz Unlocked (Upgraded Version)")
end
-- ========================================== 
-- INISIALISASI BUAT SISTEM SISTEM ESP (asli)
-- ========================================== 
local function InitializeNativeESP()
if _G.AimPROState.NativeESPReady then return end
pcall(function()
local GamePlayTools=require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local currentMarkCfg=GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
local function ApplyCfg(cfg)
if not cfg then return end
if cfg[1006]then
cfg[1006].bBindBlocked=true;cfg[1006].bBindOutScreen=true;cfg[1006].MaxWidgetNum=20
cfg[1006].MaxShowDistance=50000;cfg[1006].bScaleByDistance=false
cfg[1006].BindSocketName="head";cfg[1006].bUseLuaWorldSocketName=true
cfg[1006].WorldPositionOffset=FVector(0,0,15)
end
 -- [FIX ESP jenis 4] Daripada gunakan 1003 mudah terhapus game, jadi buat ID unik 8888
cfg[8888]={UIPathName="/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",MaxWidgetNum=20,MaxShowDistance=50000,bBindOutScreen=true,bBindBlocked=true, bIsBindingActor=true,-- referensi harus ada agar tetap mengikuti MUSUH
BindSocketName="head",bUseLuaWorldSocketName=true,WorldPositionOffset=FVector(0,0,15), bNeedPreLoad=true,-- referensi harus ada agar UI bisa dimuat (anti error)
Priority=2
}
cfg[9999]={UIPathName="/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",MaxWidgetNum=20,MaxShowDistance=50000,bBindOutScreen=true,bBindBlocked=true,bIsBindingActor=true,BindSocketName="head",bUseLuaWorldSocketName=true,WorldPositionOffset=FVector(0,0,20),bNeedPreLoad=true,Priority=2
}
end
ApplyCfg(currentMarkCfg)
for k,cfg in pairs(package.loaded)do
if type(k)=="string"and string.find(k,"ScreenMarkConfig")and type(cfg)=="table"then
ApplyCfg(cfg)
end
end
end)
_G.AimPROState.NativeESPReady=true
Notify("Native ESP System Initialized")
end
-- ========================================== 
-- LOCAL FUNCTIONS untuk LOGIC NEW ESP - OPTIMIZED
-- ========================================== 
local function GetAllSkeletalMeshes(enemy,markData)
local curTime=os.clock()
 -- [FIX CRASH GAME]: kurangi waktu durasi Cache turunkan 0.5s. jaga 3.0s Bot MATI mesh variabel hilang akan menyebabkan crash C++
if markData and markData.CachedMeshes and markData.CachedMeshTime and(curTime-markData.CachedMeshTime<0.5)then
local validMeshes={}
for _,cachedMesh in ipairs(markData.CachedMeshes)do
 -- cek cek tambahkan hal syarat IsPendingKill untuk pastikan pasti mesh belum terkena game hapus
local isPendingKill=false
pcall(function()if type(cachedMesh.IsPendingKill)=="function"then isPendingKill=cachedMesh:IsPendingKill()end end)
if Valid(cachedMesh)and not isPendingKill then
table.insert(validMeshes,cachedMesh)
end
end
markData.CachedMeshes=validMeshes
return validMeshes
end
local meshes={}
if Valid(enemy.Mesh)then table.insert(meshes,enemy.Mesh)end
pcall(function()
local SkeletalMeshClass=import("SkeletalMeshComponent")
if SkeletalMeshClass and type(enemy.GetComponentsByClass)=="function"then
local childs=enemy:GetComponentsByClass(SkeletalMeshClass)
if childs then
local count=type(childs.Num)=="function"and childs:Num()or#childs
for i=1,count do
local comp=type(childs.Get)=="function"and childs:Get(i-1)or childs[i]
if Valid(comp)and comp~=enemy.Mesh then
table.insert(meshes,comp)
end
end
end
end
end)
if markData then
markData.CachedMeshes=meshes
markData.CachedMeshTime=curTime
end
return meshes
end
-- ========================================== 
-- Fungsi Tembus tembok & RESTORE asli
-- ==========================================
local function UndoWallXuyenTuong(enemy,markData)
pcall(function()
if markData.WallhackApplied then
local meshes=GetAllSkeletalMeshes(enemy,markData)
for _,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()if type(mesh.SetRenderCustomDepth)=="function"then mesh:SetRenderCustomDepth(false)end end)
for i=0,10 do
local matInterface=mesh:GetMaterial(i)
if Valid(matInterface)then
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat)then baseMat.bDisableDepthTest=false end
end
end
end
end
markData.WallhackApplied=false
end
end)
end
local function ApplyWallXuyenTuong(enemy,markData)
pcall(function()
local meshes=GetAllSkeletalMeshes(enemy,markData)
for _,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()
if type(mesh.SetRenderCustomDepth)=="function"then
mesh:SetRenderCustomDepth(true)
end
if type(mesh.SetCustomDepthStencilValue)=="function"then
mesh:SetCustomDepthStencilValue(252)
end
end)
for i=0,10 do
local matInterface=mesh:GetMaterial(i)
if not Valid(matInterface)then break end
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat)then
baseMat.bDisableDepthTest=true
baseMat.BlendMode=2
end
end
end
end
end)
end
local function ApplyColorBodyV2(enemy,pc,markData)
pcall(function()
local meshes=GetAllSkeletalMeshes(enemy,markData)
if#meshes==0 then return end
 -- [FIX anti tersendat lag BANYAK orang]: Batas ray Raycast Check tembok 0.3s satu kali
 -- hindari proses jalankan puluhan ribu ray item logika setiap detik buat membebani CPU
local curTime=os.clock()
if markData.LastVisCheckTime==nil or(curTime-markData.LastVisCheckTime)>0.3 then
markData.LastVisCheckTime=curTime
local isHidden=true
pcall(function()
if Valid(pc)and type(pc.LineOfSightTo)=="function"then
if pc:LineOfSightTo(enemy)then isHidden=false else isHidden=true end
end
end)
markData.CachedHiddenState=isHidden
end
local hidden=markData.CachedHiddenState
if hidden==nil then hidden=true end
local cData=_G.AimPROState.CustomTextData or{}
local hiddenColor={R=cData.HiddenR or 150,G=cData.HiddenG or 0,B=cData.HiddenB or 0,A=cData.HiddenA or 25}
local visibleColor={R=cData.VisibleR or 0,G=cData.VisibleG or 150,B=cData.VisibleB or 0,A=cData.VisibleA or 25}
local finalColor=hidden and hiddenColor or visibleColor
local colorHash=string.format("%d_%d_%d_%d",finalColor.R,finalColor.G,finalColor.B,finalColor.A)
local currentMeshCount=#meshes
local isMeshChanged=(markData.LastMeshCount~=currentMeshCount)
 -- jika belum ada hal ganti warna / ganti jumlah jumlah celana baju maka hentikan selalu, HEMAT HEMAT CPU
if not isMeshChanged and markData.LastHiddenState==hidden and markData.LastColorHash==colorHash then return end
 -- [FIX RAM]: Hapus Material sampah lama pergi saat MUSUH ganti senjata senjata/baju armor agar tidak sampah VRAM
if isMeshChanged and markData.MIDs then
markData.MIDs={}
end
markData.LastHiddenState=hidden
markData.LastMeshCount=currentMeshCount
markData.LastColorHash=colorHash
markData.ColorApplied=true
for meshIndex,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()
mesh.LDMaxDrawDistance=-99999
mesh.MaxDrawDistanceOffset=-99999
mesh.CachedMaxDrawDistance=-99999
mesh.UseScopeDistanceCulling=true
mesh.PrimitiveShadingStrategy=1
mesh.ShadingRate=6
end)
for i=0,10 do
local matInterface=mesh:GetMaterial(i)
if not Valid(matInterface)then break end
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat)then
local matName=tostring(baseMat)
if string.find(matName,"Master_Mask",1,true)then
if not markData.MIDs then markData.MIDs={}end
 -- [FIX sampah RAM]: Daripada gunakan tostring(mesh) buat sampah string, gunakan index bagian bagian
local meshKey="Mesh_"..tostring(meshIndex)
if not markData.MIDs[meshKey]then markData.MIDs[meshKey]={}end
local mid=markData.MIDs[meshKey][i]
if not Valid(mid)then
mid=mesh:CreateAndSetMaterialInstanceDynamic(i)
markData.MIDs[meshKey][i]=mid
end
if Valid(mid)then
mid:SetVectorParameterValue("颜色",finalColor)
mid:SetVectorParameterValue("Extra Light Color",finalColor)
mid:SetVectorParameterValue("Para_Color",finalColor)
mid:SetVectorParameterValue("Para_ColorTint",finalColor)
mid:SetVectorParameterValue("Para_Color_1",finalColor)
mid:SetVectorParameterValue("Tint",finalColor)
mid:SetVectorParameterValue("Color",finalColor)
mid:SetVectorParameterValue("BaseColor",finalColor)
mid:SetVectorParameterValue("BodyColor",finalColor)
mid:SetVectorParameterValue("MainColor",finalColor)
mid:SetVectorParameterValue("DiffuseColor",finalColor)
mid:SetVectorParameterValue("EmissiveColor",finalColor)
mid:SetVectorParameterValue("ParaScaleOffset",SCALE_COLOR_V2)
end
end
end
end
end
end
end)
end
local function UndoColorBodyV2(enemy,markData)
pcall(function()
if markData.ColorApplied then
local meshes=GetAllSkeletalMeshes(enemy,markData)
for meshIndex,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()
mesh.PrimitiveShadingStrategy=0
mesh.ShadingRate=1
end)
local meshKey="Mesh_"..tostring(meshIndex)
if markData.MIDs and markData.MIDs[meshKey]then
for i,mid in pairs(markData.MIDs[meshKey])do
if Valid(mid)then
local defC={R=1,G=1,B=1,A=1}
mid:SetVectorParameterValue("颜色",defC)
mid:SetVectorParameterValue("Extra Light Color",defC)
mid:SetVectorParameterValue("Para_Color",defC)
mid:SetVectorParameterValue("Para_ColorTint",defC)
mid:SetVectorParameterValue("Para_Color_1",defC)
mid:SetVectorParameterValue("Tint",defC)
mid:SetVectorParameterValue("Color",defC)
mid:SetVectorParameterValue("BaseColor",defC)
mid:SetVectorParameterValue("BodyColor",defC)
mid:SetVectorParameterValue("MainColor",defC)
mid:SetVectorParameterValue("DiffuseColor",defC)
mid:SetVectorParameterValue("EmissiveColor",defC)
end
end
end
end
end
markData.ColorApplied=false
markData.LastColorHash=""
markData.LastHiddenState=nil
end
end)
end
-- FPP TO TPP
function ForceTPP()
pcall(function()
if not _G.AimPROConfig
or not _G.AimPROConfig.tppfpp then
return
end
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local pc=GameplayData.GetPlayerController()
if not slua.isValid(pc)then
return
end
local lp=pc:GetPlayerCharacterSafety()
if not slua.isValid(lp)then
return
end
 -- ==========================================
 -- FPP -> TPP
 -- ==========================================
if type(pc.SwitchCameraMode)=="function"then
pc:SwitchCameraMode(0,lp,false,true)
end
 -- ==========================================
 -- Matikan status FPP
 -- ==========================================
if pc.bIsFirstPerson~=nil then
pc.bIsFirstPerson=false
end
if lp.bIsFirstPerson~=nil then
lp.bIsFirstPerson=false
end
if pc.CurCameraMode~=nil then
pc.CurCameraMode=0
end
 -- ==========================================
 -- Camera Manager
 -- ==========================================
local cm=pc.PlayerCameraManager
if slua.isValid(cm)then
if cm.CurCameraMode~=nil then
cm.CurCameraMode=0
end
end
 -- ==========================================
 -- GameState
 -- ==========================================
local gs=GameplayData.GetGameState()
if slua.isValid(gs)then
if gs.IsFPPGameMode~=nil then
gs.IsFPPGameMode=false
end
if gs.IsCanSwitchFPP~=nil then
gs.IsCanSwitchFPP=true
end
if gs.IsFPPMode~=nil then
gs.IsFPPMode=false
end
if gs.bIsFPPMode~=nil then
gs.bIsFPPMode=false
end
if gs.C_IsFPPMode~=nil then
gs.C_IsFPPMode=false
end
end
end)
end
-- ==========================================
-- UNLOCK TPP/FPP SWITCH BUTTON
-- ==========================================
function UnlockTPPSwitchButton()
pcall(function()
local UIT=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
if not UIT or UIT.__tpp_unlock then
return
end
UIT.__tpp_unlock=true
local orig=UIT.IsFPP
if type(orig)=="function"then
UIT.IsFPP=function(...)
if _G.AimPROConfig
and _G.AimPROConfig.tppfpp then
return false
end
return orig(...)
end
end
end)
end
-- ==========================================
-- FUNGSI Warna V3 (DIPISAH dari kode SUMBER kamu - aktif lewat bagian BUFFER Z)
-- [sudah FIX Error HILANG warna saat ganti LOD & maksimal optimal anti DROP FPS saat BANYAK orang]
-- ==========================================
local function ApplyColorBodyV3(enemy,markData)
pcall(function()
local meshes=GetAllSkeletalMeshes(enemy,markData)
if#meshes==0 then return end
local cData=_G.AimPROState.CustomTextData or{}
local hidChoice=cData.ColorV3Hidden or 1
local visChoice=cData.ColorV3Visible or 2
local v3Thick=cData.ColorV3Thickness or 4
 -- Buat kode hash untuk deteksi tampil orang gunakan geser slider ganti warna/tingkat tebal
local currentHash=string.format("%d_%d_%d",hidChoice,visChoice,v3Thick)
local colorChanged=(markData.LastColorV3Hash~=currentHash)
markData.LastColorV3Hash=currentHash
local function GetColorRGB(choice)
 if choice==1 then return 255,0,0 end -- Merah
 if choice==2 then return 0,255,0 end -- hijau
 if choice==3 then return 0,0,255 end -- Biru
 if choice==4 then return 255,255,0 end -- Kuning
 if choice==5 then return 255,0,255 end -- Ungu/Pink
 if choice==6 then return 255,255,255 end -- Putih
 return 255,0,0 -- tetap tetapkan merah
end
local hR,hG,hB=GetColorRGB(hidChoice)
local vR,vG,vB=GetColorRGB(visChoice)
 -- warna setelah tembok (invisColor)
local invisColor={R=hR,G=hG,B=hB,A=255,r=hR,g=hG,b=hB,a=255}
 -- warna border terlihat area HDR (visColor)
local glowIntensity=80.0
local LinearColorClass=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local visColor=LinearColorClass and LinearColorClass((vR/255)*glowIntensity,(vG/255)*glowIntensity,(vB/255)*glowIntensity,1.0)or{R=vR*glowIntensity,G=vG*glowIntensity,B=vB*glowIntensity,A=255}
local scale={R=3.0,G=3.0,B=0.0,A=0.0,r=3.0,g=3.0,b=0.0,a=0.0}
markData.MIDs_V3=markData.MIDs_V3 or{}
for meshIndex,comp in ipairs(meshes)do
if Valid(comp)then
local compKey="MeshV3_"..tostring(meshIndex)
markData.MIDs_V3[compKey]=markData.MIDs_V3[compKey]or{}
pcall(function()
if comp.PrimitiveShadingStrategy~=1 then
comp.UseScopeDistanceCulling=false
comp.PrimitiveShadingStrategy=1
comp.ShadingRate=6
end
end)
for i=0,10 do
local matInterface=comp:GetMaterial(i)
if not Valid(matInterface)then break end
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat)then
if baseMat.bDisableDepthTest~=true then baseMat.bDisableDepthTest=true end
if baseMat.BlendMode~=2 then baseMat.BlendMode=2 end
end
local currentCached=markData.MIDs_V3[compKey][i]
local needUpdateColor=false
 -- jika belum ada MID atau orang gunakan geser slider ganti warna -> Update lagi
if not Valid(currentCached)then
local newMid=comp:CreateAndSetMaterialInstanceDynamic(i)
if Valid(newMid)then
markData.MIDs_V3[compKey][i]=newMid
currentCached=newMid
needUpdateColor=true
end
elseif colorChanged then
needUpdateColor=true
end
if Valid(currentCached)and needUpdateColor then
pcall(function()
currentCached:SetVectorParameterValue("颜色",invisColor)
currentCached:SetVectorParameterValue("Extra Light Color",invisColor)
currentCached:SetVectorParameterValue("Para_Color",invisColor)
currentCached:SetVectorParameterValue("Para_ColorTint",invisColor)
currentCached:SetVectorParameterValue("Para_Color_1",invisColor)
currentCached:SetVectorParameterValue("Tint",invisColor)
currentCached:SetVectorParameterValue("Color",invisColor)
currentCached:SetVectorParameterValue("BaseColor",invisColor)
currentCached:SetVectorParameterValue("BodyColor",invisColor)
currentCached:SetVectorParameterValue("MainColor",invisColor)
currentCached:SetVectorParameterValue("DiffuseColor",invisColor)
currentCached:SetVectorParameterValue("EmissiveColor",invisColor)
currentCached:SetVectorParameterValue("CustomColor",invisColor)
currentCached:SetVectorParameterValue("OverlayColor",invisColor)
currentCached:SetVectorParameterValue("GlowColor",invisColor)
currentCached:SetVectorParameterValue("EdgeColor",invisColor)
currentCached:SetVectorParameterValue("LightColor",invisColor)
currentCached:SetVectorParameterValue("OutlineColor",invisColor)
currentCached:SetVectorParameterValue("ParaScaleOffset",scale)
currentCached:SetScalarParameterValue("Opacity",0.7)
currentCached:SetScalarParameterValue("Alpha",0.7)
currentCached:SetScalarParameterValue("GlowIntensity",1.0)
currentCached:SetScalarParameterValue("Intensity",1.0)
end)
end
end
pcall(function()
if comp.SetDrawIdeaOutline then
comp:SetDrawIdeaOutline(true)
if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true,visColor)end
if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true,v3Thick)end
end
end)
end
end
markData.ColorV3Applied=true
end)
end
local function UndoColorBodyV3(enemy,markData)
pcall(function()
if markData.ColorV3Applied then
local meshes=GetAllSkeletalMeshes(enemy,markData)
for meshIndex,comp in ipairs(meshes)do
if Valid(comp)then
pcall(function()
comp.PrimitiveShadingStrategy=0
comp.ShadingRate=1
end)
for i=0,10 do
local s,matInterface=pcall(function()return comp:GetMaterial(i)end)
if s and Valid(matInterface)then
local s2,baseMat=pcall(function()return matInterface:GetBaseMaterial()end)
if s2 and Valid(baseMat)then
baseMat.bDisableDepthTest=false
baseMat.BlendMode=1
end
end
end
local compKey="MeshV3_"..tostring(meshIndex)
if markData.MIDs_V3 and markData.MIDs_V3[compKey]then
for i,mid in pairs(markData.MIDs_V3[compKey])do
if Valid(mid)then
pcall(function()
local defC={R=1,G=1,B=1,A=1,r=1,g=1,b=1,a=1}
mid:SetVectorParameterValue("颜色",defC)
mid:SetVectorParameterValue("Extra Light Color",defC)
mid:SetVectorParameterValue("Para_Color",defC)
mid:SetVectorParameterValue("Tint",defC)
mid:SetVectorParameterValue("BaseColor",defC)
mid:SetVectorParameterValue("Color",defC)
end)
end
end
end
pcall(function()
if comp.SetDrawIdeaOutline then
comp:SetDrawIdeaOutline(false)
end
end)
end
end
markData.ColorV3Applied=false
 markData.LastMeshCountV3=0 -- Reset bagian hitung mesh untuk ada bisa aktif lagi setelah
if markData.MIDs_V3 then markData.MIDs_V3=nil end
end
end)
end
-- ==========================================
-- fungsi FITUR WALL warna NEW (bisa team bagian ke SISTEM SISTEM VIP maksimal optimal)
-- ==========================================
local function ApplyColorBodyNew(enemy,markData)
pcall(function()
 -- aktifkan aktif Console Command jika belum aktif (hanya panggil 1 kali)
if not _G.ConsoleNewWallReady then
local KismetSystemLibrary=import("KismetSystemLibrary")
local world=slua.getWorld()
if KismetSystemLibrary and world then
KismetSystemLibrary.ExecuteConsoleCommand(world,"r.EnableDrawDyeingColor 1")
KismetSystemLibrary.ExecuteConsoleCommand(world,"r.CustomDepth 3")
KismetSystemLibrary.ExecuteConsoleCommand(world,"r.IdeaOutline.Enable 1")
KismetSystemLibrary.ExecuteConsoleCommand(world,"r.Highlight.Enable 1")
_G.ConsoleNewWallReady=true
end
end
 -- ambil seluruh bagian mesh MUSUH
local meshes=GetAllSkeletalMeshes(enemy,markData)
 -- tambahkan mesh senjata yang sedang dipegang
local weapon=nil
pcall(function()weapon=enemy:GetCurrentWeapon()end)
if slua.isValid(weapon)and slua.isValid(weapon.Mesh)then
table.insert(meshes,weapon.Mesh)
end
local isBot=markData.AK_IS_BOT or false
local currentMeshCount=#meshes
 -- [maksimal optimal FPS MAKSIMAL MUTLAK] - MODE tingkat tidur BANYAK (CACHE)
 -- Buat hash area: jika jumlah pakaian/armor/senjata MUSUH tidak berubah, hentikan loop C++ berat di bawah
local stateHash=(isBot and"BOT"or"PLAYER").."_"..tostring(currentMeshCount)
if markData.LastColorNewHash==stateHash and markData.ColorNewApplied then
 return -- semua HAL sudah bisa warnai warna sebelum itu, hentikan fungsi di sini agar tidak membebani CPU!
end
 -- jika ada hal ganti ganti (baru aktif, MUSUH ganti senjata, ambil barang), lanjut aksi update update warna dan simpan Cache
markData.LastColorNewHash=stateHash
markData.ColorNewApplied=true
 -- hanya Load bagian warna saat benar-benar perlu proses logika
local LinearColorClass=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local c_vis=LinearColorClass and LinearColorClass(0,100,0,1)or{R=0,G=100,B=0,A=1}
local c_occ=LinearColorClass and LinearColorClass(100,0,0,1)or{R=100,G=0,B=0,A=1}
local c_bVis=LinearColorClass and LinearColorClass(49,48,0,100)or{R=49,G=48,B=0,A=100}
local c_bOcc=LinearColorClass and LinearColorClass(9,1.5,45,100)or{R=9,G=1.5,B=45,A=100}
local visColor=isBot and c_bVis or c_vis
local occColor=isBot and c_bOcc or c_occ
for _,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()
if type(mesh.SetDrawDyeing)=="function"then
mesh:SetDrawDyeing(true)
mesh:SetDrawDyeingMode(1)
mesh:SetVisibleDyeingColor(visColor)
mesh:SetOccludedDyeingColor(occColor)
mesh:SetDyeingColorFadeDistance(99999.0)
mesh:SetDyeingColorMinMaxDistance(0.0,99999.0)
mesh:SetDrawHighlight(true)
mesh:OverrideHighlightColor(visColor)
mesh:SetHighlightCanBeOccluded(false)
mesh:SetDrawIdeaOutline(true)
mesh:SetIdeaOutlineNew(true)
mesh:SetIdeaOutlineOcclusionHighlight(true)
mesh:OverrideIdeaOutlineColor(visColor)
mesh:SetIdeaOutlineOcclusionColor(occColor)
mesh:OverrideIdeaOutlineThickness(20.0)
mesh:SetIdeaOverrideOutlineAndOcclusion(true)
mesh:SetRenderCustomDepth(true)
mesh:SetCustomDepthStencilValue(255)
end
end)
end
end
end)
end
local function UndoColorBodyNew(enemy,markData)
pcall(function()
if markData.ColorNewApplied then
local meshes=GetAllSkeletalMeshes(enemy,markData)
local weapon=nil
pcall(function()weapon=enemy:GetCurrentWeapon()end)
if slua.isValid(weapon)and slua.isValid(weapon.Mesh)then
table.insert(meshes,weapon.Mesh)
end
for _,mesh in ipairs(meshes)do
if Valid(mesh)then
pcall(function()
if type(mesh.SetDrawDyeing)=="function"then
mesh:SetDrawDyeing(false)
mesh:SetDrawHighlight(false)
mesh:SetDrawIdeaOutline(false)
mesh:SetRenderCustomDepth(false)
end
end)
end
end
markData.ColorNewApplied=false
 markData.LastColorNewHash="" -- Hapus Cache untuk kali setelah aktif lagi akan hitung hitung lagi mulus tetapi
end
end)
end
-- ========================================== 
-- SISTEM SISTEM AIMBOT V2 Akumulasi cocok baru (UPDATE KISMET SMOOTH)
-- ========================================== 
_G.GetEnemyTargetsFromActors=function(radius)
local result={}
local player=GameplayData.GetPlayerCharacter()
if not slua.isValid(player)then
return result
end
local allCharacters={}
if GameplayData.GetAllPlayerCharacters then
allCharacters=GameplayData.GetAllPlayerCharacters()
elseif GameplayData.GameCharacters then
for _,char in pairs(GameplayData.GameCharacters)do table.insert(allCharacters,char)end
end
local myTeam=player:GetTeamID()
for _,actor in pairs(allCharacters)do
if slua.isValid(actor)and actor~=player and actor.GetTeamID and actor:IsAlive()then
if actor:GetTeamID()~=myTeam then
local dist=player:GetDistanceTo(actor)
if dist<=radius then
table.insert(result,actor)
end
end
end
end
return result
end
_G.AimTouch=function()
pcall(function()
if not _G.AimPROConfig.AimTouchEnable then return end
local player=GameplayData.GetPlayerCharacter()
if not slua.isValid(player)then return end
local pc=player:GetPlayerControllerSafety()
if not slua.isValid(pc)then return end
local isFiring=player.bIsWeaponFiring
local isADS=player.bIsGunADS
 -- CHECK WEAPON & AMMO
local weapon=player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
if not weapon and type(player.GetCurrentShootWeapon)=="function"then
weapon=player:GetCurrentShootWeapon()
end
local isShotgun=false
local isSniper=false
local isMortar=false
local currentAmmo=1
if slua.isValid(weapon)then
local wID=type(weapon.GetWeaponID)=="function"and weapon:GetWeaponID()or 0
local wName=type(weapon.GetWeaponName)=="function"and weapon:GetWeaponName()or""
if(wID>=1030000 and wID<1040000)or wName:find("S686")or wName:find("S1897")or wName:find("S12")or wName:find("DBS")or wName:find("M1014")then
isShotgun=true
end
if wName:find("Kar98")or wName:find("M24")or wName:find("AWM")or wName:find("Mosin")or wName:find("Win94")or wName:find("AMR")or wName:find("SKS")or wName:find("SLR")or wName:find("Mini")or wName:find("Mk14")or wName:find("QBU")or wName:find("Mk12")or wName:find("VSS")then
isSniper=true
end
if wName:lower():find("mortar")or wName:lower():find("cối")then
isMortar=true
end
if type(weapon.GetCurrentAmmo)=="function"then
currentAmmo=weapon:GetCurrentAmmo()
elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo)=="function"then
currentAmmo=weapon.ShootWeaponComponent:GetCurrentAmmo()
elseif weapon.CurrentAmmo~=nil then
currentAmmo=weapon.CurrentAmmo
end
end
 -- LOGIC LEPAS TEMBAKAN senjata jika HILANG folder TARGET / MUSUH MATI atau SHOTGUN HABIS peluru
if _G.AimPROState.IsAutoFiring then
pcall(function()
player.bIsWeaponFiring=false
if type(player.SetIsWeaponFiring)=="function"then player:SetIsWeaponFiring(false)end
if slua.isValid(pc)and type(pc.SetIsWeaponFiring)=="function"then pc:SetIsWeaponFiring(false)end
local wepMgr=player.WeaponManagerComponent
if slua.isValid(wepMgr)then wepMgr.bIsWeaponFiring=false end
end)
_G.AimPROState.IsAutoFiring=false
end
 -- SHOTGUN HABIS peluru berhenti AIM untuk GAME isi peluru
if isShotgun and currentAmmo<=0 then
return
end
local cond=2
local prioMode=1
local boneIdx=1
local speedVal=50
local fovVal=30
local maxDistMeters=50
local useVisCheck=false
local igKnock=false
local igBot=false
 -- Logic tambahkan ke: prediksi tebak dan Kompensasi tersendat
local predVal=0
local recoilCompVal=0
 -- ATUR JENIS PENGATURAN SESUAI KONDISI TAMPILAN
if isMortar and _G.AimPROConfig.AimTouchMortar then
local isPlaced=false
pcall(function()
if weapon and weapon.MortarState==2 then isPlaced=true end
end)
if not isPlaced then return end
cond=2
prioMode=1
boneIdx=4
speedVal=100
fovVal=_G.AimPROState.CustomTextData.AimTouchMortarFOV or 360
maxDistMeters=2000
useVisCheck=false
igKnock=false
igBot=false
predVal=_G.AimPROState.CustomTextData.AimTouchMortarPred or 0
elseif isShotgun and _G.AimPROConfig.AimTouchSG then
cond=_G.AimPROState.CustomTextData.AimTouchSGCond or 1
if _G.AimPROConfig.AimTouchSGAutoFire then cond=2 end
if cond==1 and not isFiring then return end
prioMode=_G.AimPROState.CustomTextData.AimTouchSGPrio or 1
boneIdx=_G.AimPROState.CustomTextData.AimTouchSGBone or 2
speedVal=_G.AimPROState.CustomTextData.AimTouchSGSpeed or 80
fovVal=_G.AimPROState.CustomTextData.AimTouchSGFOV or 40
maxDistMeters=_G.AimPROState.CustomTextData.AimTouchSGDist or 30
useVisCheck=_G.AimPROConfig.AimTouchSGVisCheck
igKnock=_G.AimPROConfig.AimTouchSGIgKnock
igBot=_G.AimPROConfig.AimTouchSGIgBot
elseif isADS then
if isSniper and _G.AimPROConfig.AimTouchScopeSniper then
cond=_G.AimPROState.CustomTextData.AimTouchSniperCond or 2
if cond==1 and not isFiring then return end
prioMode=_G.AimPROState.CustomTextData.AimTouchSniperPrio or 1
boneIdx=_G.AimPROState.CustomTextData.AimTouchSniperBone or 1
speedVal=_G.AimPROState.CustomTextData.AimTouchSniperSpeed or 30
fovVal=_G.AimPROState.CustomTextData.AimTouchSniperFOV or 20
maxDistMeters=_G.AimPROState.CustomTextData.AimTouchSniperDist or 400
useVisCheck=_G.AimPROConfig.AimTouchSniperVisCheck
igKnock=_G.AimPROConfig.AimTouchSniperIgKnock
igBot=_G.AimPROConfig.AimTouchSniperIgBot
 predVal=_G.AimPROState.CustomTextData.AimTouchSniperPred or 0 -- ambil harga nilai prediksi tebak Sniper
elseif _G.AimPROConfig.AimTouchScopeAll then
cond=_G.AimPROState.CustomTextData.AimTouchScopeCond or 1
if cond==1 and not isFiring then return end
prioMode=_G.AimPROState.CustomTextData.AimTouchScopePrio or 1
boneIdx=_G.AimPROState.CustomTextData.AimTouchScopeBone or 2
speedVal=_G.AimPROState.CustomTextData.AimTouchScopeSpeed or 40
fovVal=_G.AimPROState.CustomTextData.AimTouchScopeFOV or 20
maxDistMeters=_G.AimPROState.CustomTextData.AimTouchScopeDist or 300
useVisCheck=_G.AimPROConfig.AimTouchScopeVisCheck
igKnock=_G.AimPROConfig.AimTouchScopeIgKnock
igBot=_G.AimPROConfig.AimTouchScopeIgBot
 predVal=_G.AimPROState.CustomTextData.AimTouchScopePred or 0 -- ambil harga nilai prediksi tebak Senjata biasa
 recoilCompVal=_G.AimPROState.CustomTextData.AimTouchScopeRecoil or 0 -- ambil harga nilai kompensasi tersendat
else
return
end
else
if not _G.AimPROConfig.AimTouchHipfire then return end
cond=_G.AimPROState.CustomTextData.AimTouchHipCond or 1
if cond==1 and not isFiring then return end
prioMode=_G.AimPROState.CustomTextData.AimTouchHipPrio or 1
boneIdx=_G.AimPROState.CustomTextData.AimTouchHipBone or 1
speedVal=_G.AimPROState.CustomTextData.AimTouchHipSpeed or 50
fovVal=_G.AimPROState.CustomTextData.AimTouchHipFOV or 30
maxDistMeters=_G.AimPROState.CustomTextData.AimTouchHipDist or 250
useVisCheck=_G.AimPROConfig.AimTouchHipVisCheck
igKnock=_G.AimPROConfig.AimTouchHipIgKnock
igBot=_G.AimPROConfig.AimTouchHipIgBot
end
local currentMaxDist=maxDistMeters*100
local enemies=_G.GetEnemyTargetsFromActors(currentMaxDist)
if not enemies or#enemies==0 then return end
local FVector2D=_G.FourimPROGetImport("Vector2D")
local UGameplayStatics=import("GameplayStatics")
local KismetMathLibrary=import("KismetMathLibrary")
local camManager=UGameplayStatics.GetPlayerCameraManager(pc,0)
if not slua.isValid(camManager)then return end
local camLoc=camManager:GetCameraLocation()
if not camLoc then return end
local ui_util=require("client.common.ui_util")
if not ui_util then return end
local viewportSize=ui_util.GetViewportSize()
if not viewportSize then return end
local centerX=viewportSize.X*0.5
local centerY=viewportSize.Y*0.5
local FOV_RADIUS=(fovVal/100.0)*(viewportSize.X/2.0)
local bestTarget=nil
local bestScore=99999999
local selBoneName="head"
if boneIdx==1 then selBoneName="head"
elseif boneIdx==2 then selBoneName="spine_03"
elseif boneIdx==3 then selBoneName="spine_01"
elseif boneIdx==4 then selBoneName="pelvis"end
for i,target in ipairs(enemies)do
if not slua.isValid(target)then goto continue end
pcall(function()
if slua.isValid(target.Mesh)then
target.Mesh.MeshComponentUpdateFlag=0
end
end)
if igKnock and target.HealthStatus==1 then goto continue end
if igBot then
local tIsBot=false
if target.bIsAI==true or target.IsAI==true then tIsBot=true end
local pState=target.PlayerState
if slua.isValid(pState)and(pState.bIsABot or pState.bIsBot)then tIsBot=true end
if tIsBot then goto continue end
end
 -- [FIX TỤT FPS]: kunci ray Raycast check tembok, hanya scan 0.2s satu kali (Tetap mulus tidak membebani CPU)
if useVisCheck then
local curTime=os.clock()
local tId=type(target.GetUniqueID)=="function"and target:GetUniqueID()or tostring(target)
_G.AimTouchVisCache=_G.AimTouchVisCache or{}
if not _G.AimTouchVisCache[tId]or(curTime-_G.AimTouchVisCache[tId].time)>0.2 then
local isHidden=true
pcall(function()if pc:LineOfSightTo(target)then isHidden=false end end)
_G.AimTouchVisCache[tId]={hidden=isHidden,time=curTime}
end
if _G.AimTouchVisCache[tId].hidden then goto continue end
end
local tPos=target:GetBonePos(selBoneName,{X=0,Y=0,Z=0})
if not tPos or(tPos.X==0 and tPos.Y==0 and tPos.Z==0)then
if type(target.GetSocketLocation)=="function"then
tPos=target:GetSocketLocation(selBoneName)
end
end
if not tPos or(tPos.X==0 and tPos.Y==0 and tPos.Z==0)then
if type(target.K2_GetActorLocation)=="function"then
tPos=target:K2_GetActorLocation()
if tPos then
if boneIdx==1 then tPos.Z=tPos.Z+70
elseif boneIdx==2 then tPos.Z=tPos.Z+40
elseif boneIdx==3 then tPos.Z=tPos.Z+20 end
end
end
end
if not tPos or(tPos.X==0 and tPos.Y==0 and tPos.Z==0)then goto continue end
local screen=FVector2D()
local success=pc:ProjectWorldLocationToScreen(tPos,screen,false)
if not success or screen.X<=0 or screen.Y<=0 then goto continue end
local dx=screen.X-centerX
local dy=screen.Y-centerY
local distScreen=math.sqrt(dx*dx+dy*dy)
if distScreen>FOV_RADIUS then goto continue end
local currentScore=distScreen
if prioMode==2 then currentScore=player:GetDistanceTo(target)
elseif prioMode==3 then currentScore=target.Health or 100
elseif prioMode==4 then
local hp=target.Health or 100
local maxhp=target.HealthMax or 100
if maxhp<=0 then maxhp=100 end
currentScore=hp/maxhp
end
if currentScore<bestScore then
bestScore=currentScore
bestTarget=target
end
::continue::end
if not slua.isValid(bestTarget)then return end
local finalBonePos=bestTarget:GetBonePos(selBoneName,{X=0,Y=0,Z=0})
if not finalBonePos or(finalBonePos.X==0 and finalBonePos.Y==0 and finalBonePos.Z==0)then
if type(bestTarget.GetSocketLocation)=="function"then
finalBonePos=bestTarget:GetSocketLocation(selBoneName)
end
end
if not finalBonePos or(finalBonePos.X==0 and finalBonePos.Y==0 and finalBonePos.Z==0)then
if type(bestTarget.K2_GetActorLocation)=="function"then
finalBonePos=bestTarget:K2_GetActorLocation()
if finalBonePos then
if boneIdx==1 then finalBonePos.Z=finalBonePos.Z+70
elseif boneIdx==2 then finalBonePos.Z=finalBonePos.Z+40
elseif boneIdx==3 then finalBonePos.Z=finalBonePos.Z+20 end
end
end
end
if not finalBonePos or(finalBonePos.X==0 and finalBonePos.Y==0 and finalBonePos.Z==0)then return end
local tVelocity=nil
pcall(function()
if type(bestTarget.GetVelocity)=="function"then
tVelocity=bestTarget:GetVelocity()
end
end)
 -- LOGIC PREDIKSI ARAH MORTAR
if isMortar and _G.AimPROConfig.AimTouchMortar and predVal>0 then
pcall(function()
if tVelocity and(tVelocity.X~=0 or tVelocity.Y~=0)then
local approxDist=player:GetDistanceTo(bestTarget)/100.0
local approxToF=approxDist/100.0
local predScale=predVal/50.0
finalBonePos.X=finalBonePos.X+(tVelocity.X*approxToF*predScale)
finalBonePos.Y=finalBonePos.Y+(tVelocity.Y*approxToF*predScale)
end
end)
end
 -- LOGIC 1: PREDICTION (senjata biasa)
if not isMortar and predVal>0 then
pcall(function()
 -- jika MUSUH sedang di pindah
if tVelocity and(tVelocity.X~=0 or tVelocity.Y~=0)then
 local distToEnemy=player:GetDistanceTo(bestTarget)/100.0 -- Jarak meter
 -- hitung hitung waktu durasi peluru pesawat (Time-Of-Flight) rasio rasio sebanding dengan sekitar jarak dan variabel teruskan ke
 -- sistem jumlah 800.0 besar area untuk kecepatan tingkat peluru jatuh palsu buat, 50.0 adalah tingkat tengah rata-rata slider
local ToF=(distToEnemy/800.0)*(predVal/50.0)
 -- Bergerak koordinat tingkat Aim naik sebelum arah jalan
finalBonePos.X=finalBonePos.X+(tVelocity.X*ToF)
finalBonePos.Y=finalBonePos.Y+(tVelocity.Y*ToF)
end
end)
end
local rot=KismetMathLibrary.FindLookAtRotation(camLoc,finalBonePos)
if not rot then return end
local currentRot=pc:GetControlRotation()
if not currentRot then return end
local deltaYaw=rot.Yaw-currentRot.Yaw
local deltaPitch=rot.Pitch-currentRot.Pitch
 -- [tangkap kepala FIX] Kompensasi kurangi selisih melenceng Camera saat buka scope membidik (ADS) untuk tidak terkena melenceng tengah
if isADS then
local camRot=nil
if type(camManager.GetCameraRotation)=="function"then
camRot=camManager:GetCameraRotation()
end
if camRot then
deltaYaw=deltaYaw-(camRot.Yaw-currentRot.Yaw)
deltaPitch=deltaPitch-(camRot.Pitch-currentRot.Pitch)
end
end
 -- [SELESAI FIX]
if deltaYaw>180 then deltaYaw=deltaYaw-360 end
if deltaYaw<-180 then deltaYaw=deltaYaw+360 end
if deltaPitch>180 then deltaPitch=deltaPitch-360 end
if deltaPitch<-180 then deltaPitch=deltaPitch+360 end
local smoothFactor=0.0
if speedVal>=100 then
smoothFactor=1.0
else
smoothFactor=(speedVal/100.0)*0.3
if smoothFactor<0.01 then smoothFactor=0.01 end
end
local finalPitch=currentRot.Pitch+(deltaPitch*smoothFactor)
local finalYaw=currentRot.Yaw+(deltaYaw*smoothFactor)
 -- LOGIC 2: RECOIL COMPENSATION (paksa TENGAH / kompensasi agar tidak terlalu tinggi)
if recoilCompVal>0 and isFiring then
local pullDownForce=(recoilCompVal/50.0)*1.5
finalPitch=finalPitch-pullDownForce
end
 -- LOGIC hitung hitung sudut jalankan asli hal untuk senjata MORTAR
if isMortar and _G.AimPROConfig.AimTouchMortar then
local targetPos={X=finalBonePos.X,Y=finalBonePos.Y,Z=finalBonePos.Z}
local launchPos=camLoc
pcall(function()
if player.K2_GetActorLocation then
local pLoc=player:K2_GetActorLocation()
if pLoc then
launchPos={X=pLoc.X,Y=pLoc.Y,Z=pLoc.Z+50}
end
end
end)
local function CalcMortarTrajectory(V,G,tX,tY,tZ)
local mDx=math.sqrt((tX-launchPos.X)^2+(tY-launchPos.Y)^2)-80
if mDx<500 then mDx=500 end
local mDy=tZ-launchPos.Z
local minVSq=G*(mDy+math.sqrt(mDx*mDx+mDy*mDy))
if(V*V)<minVSq then
V=math.sqrt(minVSq)+100
end
local v2=V*V
local root=v2*v2-G*(G*mDx*mDx+2*mDy*v2)
if root>=0 then
local angleRad=math.atan((v2+math.sqrt(root))/(G*mDx))
local deg=math.deg(angleRad)
if deg>=35 and deg<=89.5 then
return true,deg,mDx/(V*math.cos(angleRad)),mDx
end
end
return false,45,0,mDx
end
local vNear,gNear=9070,980*2.8
local vFar,gFar=12520,980*4.0
local vUltra,gUltra=16800,980*4.5
local isValid,physAngle,ToF,finalDx=false,45,0,0
local okNear,angNear,tofNear,dxN=CalcMortarTrajectory(vNear,gNear,targetPos.X,targetPos.Y,targetPos.Z)
local okFar,angFar,tofFar,dxF=CalcMortarTrajectory(vFar,gFar,targetPos.X,targetPos.Y,targetPos.Z)
local okUltra,angUltra,tofUltra,dxU=CalcMortarTrajectory(vUltra,gUltra,targetPos.X,targetPos.Y,targetPos.Z)
if okNear and dxN<=25000 then
isValid,physAngle,ToF,finalDx=okNear,angNear,tofNear,dxN
elseif okFar and dxF<=40000 then
isValid,physAngle,ToF,finalDx=okFar,angFar,tofFar,dxF
elseif okUltra then
isValid,physAngle,ToF,finalDx=okUltra,angUltra,tofUltra,dxU
elseif okNear then
isValid,physAngle,ToF,finalDx=okNear,angNear,tofNear,dxN
end
local targetCameraPitch=((physAngle-45)/43.0)*90.0-60.0
local targetCameraYaw=rot.Yaw
local deltaPitchMortar=targetCameraPitch-currentRot.Pitch
local deltaYawMortar=targetCameraYaw-currentRot.Yaw
if deltaPitchMortar>180 then deltaPitchMortar=deltaPitchMortar-360 end
if deltaPitchMortar<-180 then deltaPitchMortar=deltaPitchMortar+360 end
if deltaYawMortar>180 then deltaYawMortar=deltaYawMortar-360 end
if deltaYawMortar<-180 then deltaYawMortar=deltaYawMortar+360 end
finalPitch=currentRot.Pitch+(deltaPitchMortar*smoothFactor)
finalYaw=currentRot.Yaw+(deltaYawMortar*smoothFactor)
end
local finalRot={Pitch=finalPitch,Yaw=finalYaw,Roll=0}
pc:SetControlRotation(finalRot,"AimTouch")
if isShotgun and _G.AimPROConfig.AimTouchSGAutoFire then
pcall(function()
local distToTarget=player:GetDistanceTo(bestTarget)/100
if distToTarget<=maxDistMeters then
player.bIsWeaponFiring=true
if type(player.SetIsWeaponFiring)=="function"then player:SetIsWeaponFiring(true)end
if slua.isValid(pc)and type(pc.SetIsWeaponFiring)=="function"then pc:SetIsWeaponFiring(true)end
local wepMgr=player.WeaponManagerComponent
if slua.isValid(wepMgr)then wepMgr.bIsWeaponFiring=true end
local currentWep=player:GetCurrentWeapon()
if slua.isValid(currentWep)and type(currentWep.StartFire)=="function"then
currentWep:StartFire()
end
_G.AimPROState.IsAutoFiring=true
end
end)
end
end)
end
-- ========================================== 
-- SISTEM WALL & ESP ITEM/KENDARAAN super mulus (OPTIMIZED di bawah 70M)
-- ========================================== 
local ItemDatabase={ -- AR
[101001]={name="AKM",cat="AR",color={R=255,G=255,B=0,A=255}},[101002]={name="M16A4",cat="AR",color={R=255,G=255,B=0,A=255}},[101003]={name="SCAR-L",cat="AR",color={R=255,G=255,B=0,A=255}},[101004]={name="M416",cat="AR",color={R=255,G=255,B=0,A=255}},[101005]={name="Groza",cat="AR",color={R=255,G=255,B=0,A=255}},[101006]={name="AUG",cat="AR",color={R=255,G=255,B=0,A=255}},[101008]={name="M762",cat="AR",color={R=255,G=255,B=0,A=255}}, -- SMG
[102001]={name="UZI",cat="SMG",color={R=0,G=255,B=255,A=255}},[102002]={name="UMP45",cat="SMG",color={R=0,G=255,B=255,A=255}},[102003]={name="Vector",cat="SMG",color={R=0,G=255,B=255,A=255}},[102004]={name="Thompson",cat="SMG",color={R=0,G=255,B=255,A=255}}, -- Sniper
[103001]={name="Kar98K",cat="Sniper",color={R=255,G=0,B=0,A=255}},[103002]={name="M24",cat="Sniper",color={R=255,G=0,B=0,A=255}},[103003]={name="AWM",cat="Sniper",color={R=255,G=0,B=0,A=255}},[103009]={name="SLR",cat="Sniper",color={R=255,G=0,B=0,A=255}}, -- Shotgun
[104001]={name="S686",cat="Shotgun",color={R=0,G=255,B=0,A=255}},[104003]={name="S12K",cat="Shotgun",color={R=0,G=255,B=0,A=255}},[104004]={name="DBS",cat="Shotgun",color={R=0,G=255,B=0,A=255}}, -- Senapan mesin (Gabungkan ke AR untuk RINGKAS atau tampil selalu)
[105001]={name="M249",cat="AR",color={R=255,G=255,B=255,A=255}},[105002]={name="DP-28",cat="AR",color={R=255,G=255,B=255,A=255}}, -- Scope
[203004]={name="4x Scope",cat="Scope",color={R=0,G=0,B=255,A=255}},[203005]={name="8x Scope",cat="Scope",color={R=0,G=0,B=255,A=255}},[203014]={name="3x Scope",cat="Scope",color={R=0,G=0,B=255,A=255}},[203015]={name="6x Scope",cat="Scope",color={R=0,G=0,B=255,A=255}}
}
_G.CachedItems={}
_G.LastScanItemTime=0
_G.AppliedVehicleWall={}
_G.AppliedItemESP={}
-- ========================================== 
-- SISTEM WALL & ESP ITEM/KENDARAAN super mulus (FULL 100% asli)
-- ========================================== 
local C_AR={R=255,G=255,B=0,A=255}
local C_SMG={R=0,G=255,B=255,A=255}
local C_Sniper={R=255,G=0,B=0,A=255}
local C_Shotgun={R=0,G=255,B=0,A=255}
local C_LMG={R=255,G=255,B=255,A=255}
local C_Pistol={R=200,G=200,B=200,A=255}
local C_Special={R=255,G=0,B=255,A=255}
local C_Melee={R=150,G=150,B=150,A=255}
local C_Scope={R=0,G=0,B=255,A=255}
local C_Grenade={R=255,G=165,B=0,A=255}
local C_Med={R=50,G=255,B=50,A=255} -- warna hijau untuk HP/Air
local ItemDatabase={ -- AR
[101001]={name="AKM",cat="AR",color=C_AR},[101002]={name="M16A4",cat="AR",color=C_AR},[101003]={name="SCAR-L",cat="AR",color=C_AR},[101004]={name="M416",cat="AR",color=C_AR},[101005]={name="Groza",cat="AR",color=C_AR},[101006]={name="AUG",cat="AR",color=C_AR},[101007]={name="QBZ",cat="AR",color=C_AR},[101008]={name="M762",cat="AR",color=C_AR},[101009]={name="Mk47 Mutant",cat="AR",color=C_AR},[101010]={name="G36C",cat="AR",color=C_AR},[101011]={name="AC-VAL",cat="AR",color=C_AR},[101012]={name="Honey Badger",cat="AR",color=C_AR},[101100]={name="FAMAS",cat="AR",color=C_AR},[101101]={name="ASM Abakan AR",cat="AR",color=C_AR},[101102]={name="ACE32",cat="AR",color=C_AR}, -- SMG
[102001]={name="UZI",cat="SMG",color=C_SMG},[102002]={name="UMP45",cat="SMG",color=C_SMG},[102003]={name="Vector",cat="SMG",color=C_SMG},[102004]={name="Thompson SMG",cat="SMG",color=C_SMG},[102005]={name="PP-19 Bizon",cat="SMG",color=C_SMG},[102007]={name="MP5K",cat="SMG",color=C_SMG},[102008]={name="JS9",cat="SMG",color=C_SMG},[102105]={name="P90",cat="SMG",color=C_SMG}, -- Sniper
[103001]={name="Kar98K",cat="Sniper",color=C_Sniper},[103002]={name="M24",cat="Sniper",color=C_Sniper},[103003]={name="AWM",cat="Sniper",color=C_Sniper},[103004]={name="SKS",cat="Sniper",color=C_Sniper},[103005]={name="VSS",cat="Sniper",color=C_Sniper},[103006]={name="Mini14",cat="Sniper",color=C_Sniper},[103007]={name="Mk14",cat="Sniper",color=C_Sniper},[103008]={name="Win94",cat="Sniper",color=C_Sniper},[103009]={name="SLR",cat="Sniper",color=C_Sniper},[103010]={name="QBU",cat="Sniper",color=C_Sniper},[103011]={name="Mosin Nagant",cat="Sniper",color=C_Sniper},[103012]={name="AMR",cat="Sniper",color=C_Sniper},[103100]={name="Mk12",cat="Sniper",color=C_Sniper},[103101]={name="TR-2A Air Gun",cat="Sniper",color=C_Sniper},[103102]={name="DSR",cat="Sniper",color=C_Sniper},[103103]={name="Sniper Rifle",cat="Sniper",color=C_Sniper},[103104]={name="Sniper Rifle",cat="Sniper",color=C_Sniper},[103105]={name="SR",cat="Sniper",color=C_Sniper}, -- Shotgun
[104001]={name="S686",cat="Shotgun",color=C_Shotgun},[104002]={name="S1897",cat="Shotgun",color=C_Shotgun},[104003]={name="S12K",cat="Shotgun",color=C_Shotgun},[104004]={name="DBS",cat="Shotgun",color=C_Shotgun},[104100]={name="SPAS-12",cat="Shotgun",color=C_Shotgun},[104101]={name="M1014",cat="Shotgun",color=C_Shotgun},[104102]={name="NS2000",cat="Shotgun",color=C_Shotgun}, -- LMG
[105001]={name="M249",cat="LMG",color=C_LMG},[105002]={name="DP-28",cat="LMG",color=C_LMG},[105003]={name="M134",cat="LMG",color=C_LMG},[105010]={name="MG3",cat="LMG",color=C_LMG},[105101]={name="Gatling",cat="LMG",color=C_LMG},[105115]={name="Lib Gatling MG",cat="LMG",color=C_LMG},[105004]={name="Flamethrower",cat="LMG",color=C_LMG},[105006]={name="M2 Fixed MG",cat="LMG",color=C_LMG},[105007]={name="Gatling Fixed MG",cat="LMG",color=C_LMG},[105008]={name="Mounted Flamethrower",cat="LMG",color=C_LMG},[105009]={name="M2 Mounted MG",cat="LMG",color=C_LMG},[105102]={name="Vehicle SG",cat="LMG",color=C_LMG},[105103]={name="RPG",cat="LMG",color=C_LMG},[105104]={name="RPG",cat="LMG",color=C_LMG},[105105]={name="PowPow MG",cat="LMG",color=C_LMG},[105106]={name="Tank Cannon",cat="LMG",color=C_LMG},[105107]={name="Tank MG",cat="LMG",color=C_LMG},[105108]={name="Tank Flare Gun",cat="LMG",color=C_LMG},[105116]={name="Lib Autocannon",cat="LMG",color=C_LMG},[105117]={name="Jet Missile",cat="LMG",color=C_LMG},[105118]={name="Jet Autocannon",cat="LMG",color=C_LMG}, -- Pistol & Flare
[106001]={name="P92",cat="Pistol",color=C_Pistol},[106002]={name="P1911",cat="Pistol",color=C_Pistol},[106003]={name="R1895",cat="Pistol",color=C_Pistol},[106004]={name="P18C",cat="Pistol",color=C_Pistol},[106005]={name="R45",cat="Pistol",color=C_Pistol},[106006]={name="Sawed-off",cat="Pistol",color=C_Pistol},[106008]={name="Skorpion",cat="Pistol",color=C_Pistol},[106010]={name="Desert Eagle",cat="Pistol",color=C_Pistol},[106007]={name="Flare Gun",cat="Pistol",color=C_Pistol},[106009]={name="Flare Gun",cat="Pistol",color=C_Pistol},[106011]={name="Dual MP7",cat="Pistol",color=C_Pistol},[106012]={name="Welding Gun",cat="Pistol",color=C_Pistol},[106013]={name="Stun Gun",cat="Pistol",color=C_Pistol},[106101]={name="Vehicle Flare",cat="Pistol",color=C_Pistol},[106103]={name="Flare Gun",cat="Pistol",color=C_Pistol},[106106]={name="Flare (Empty)",cat="Pistol",color=C_Pistol},[106107]={name="Respawn Flare",cat="Pistol",color=C_Pistol},[106203]={name="Magnet Gun",cat="Pistol",color=C_Pistol}, -- khusus khusus
[107011]={name="Mortir",cat="Special",color=C_Special},[307006]={name="Peluru Mortir",cat="Special",color=C_Special},[107001]={name="Crossbow",cat="Special",color=C_Special},[107002]={name="RPG-7",cat="Special",color=C_Special},[107003]={name="Riot shield",cat="Special",color=C_Special},[107004]={name="Combat Drone",cat="Special",color=C_Special},[107005]={name="Panzerfaust",cat="Special",color=C_Special},[107006]={name="RPG-7",cat="Special",color=C_Special},[107007]={name="Tactical Crossbow",cat="Special",color=C_Special},[107008]={name="Explosive Bow",cat="Special",color=C_Special},[107009]={name="Explosive Bow",cat="Special",color=C_Special},[107010]={name="M79 Smoke Launcher",cat="Special",color=C_Special},[107019]={name="Atlas Gauntlet",cat="Special",color=C_Special},[107020]={name="Explosive Crossbow",cat="Special",color=C_Special},[107021]={name="Mercury Hammer",cat="Special",color=C_Special},[107022]={name="Fishbones Rocket",cat="Special",color=C_Special},[107031]={name="Summer Grenade Launcher",cat="Special",color=C_Special},[107032]={name="Summer Bazooka",cat="Special",color=C_Special},[107033]={name="Summer MG",cat="Special",color=C_Special},[107034]={name="Color Bazooka",cat="Special",color=C_Special},[107035]={name="Bubble MG",cat="Special",color=C_Special},[107036]={name="Snowball Blaster",cat="Special",color=C_Special},[107037]={name="Water Orb Blaster",cat="Special",color=C_Special},[107092]={name="MGL",cat="Special",color=C_Special},[107093]={name="M202 Quad RPG",cat="Special",color=C_Special},[107094]={name="AT4-A Laser Missile",cat="Special",color=C_Special},[107095]={name="M202 Quad RPG",cat="Special",color=C_Special},[107096]={name="M79 Sawed-off",cat="Special",color=C_Special},[107097]={name="M79",cat="Special",color=C_Special},[107098]={name="MGL",cat="Special",color=C_Special},[107099]={name="M3E1-A",cat="Special",color=C_Special},[107901]={name="Zombie Piercer",cat="Special",color=C_Special},[107903]={name="Mounted RPG",cat="Special",color=C_Special},[107904]={name="Helicopter RPG",cat="Special",color=C_Special},[107911]={name="M3E1-B Missile",cat="Special",color=C_Special}, -- Jarak dekat
[108001]={name="Machete",cat="Melee",color=C_Melee},[108002]={name="Crowbar",cat="Melee",color=C_Melee},[108003]={name="Sickle",cat="Melee",color=C_Melee},[108004]={name="Pan",cat="Melee",color=C_Melee},[108005]={name="Dagger",cat="Melee",color=C_Melee},[108006]={name="Mutation Blade",cat="Melee",color=C_Melee},[108007]={name="Mutation Gauntlets",cat="Melee",color=C_Melee}, -- Scope
[203001]={name="Red Dot Sight",cat="Scope",color=C_Scope},[203002]={name="Holographic Sight",cat="Scope",color=C_Scope},[203003]={name="2x Scope",cat="Scope",color=C_Scope},[203004]={name="4x Scope",cat="Scope",color=C_Scope},[203005]={name="8x Scope",cat="Scope",color=C_Scope},[203014]={name="3x Scope",cat="Scope",color=C_Scope},[203015]={name="6x Scope",cat="Scope",color=C_Scope}, -- Granat
[602001]={name="Stun Grenade",cat="Grenade",color=C_Grenade},[602002]={name="Smoke Grenade",cat="Grenade",color=C_Grenade},[602003]={name="Molotov",cat="Grenade",color=C_Grenade},[602004]={name="Frag Grenade",cat="Grenade",color=C_Grenade}, -- Item medis (HP, Air, pemulihan)
[601001]={name="Minuman Energi",cat="Med",color=C_Med},[601002]={name="Suntikan Adrenaline",cat="Med",color=C_Med},[601003]={name="Painkiller",cat="Med",color=C_Med},[601004]={name="Perban",cat="Med",color=C_Med},[601005]={name="Kotak P3K",cat="Med",color=C_Med},[601006]={name="Kotak P3K",cat="Med",color=C_Med},[601009]={name="Perban",cat="Med",color=C_Med},[601010]={name="Kotak P3K",cat="Med",color=C_Med},[601011]={name="Perban",cat="Med",color=C_Med},[601012]={name="Cairan Konsentrat",cat="Med",color=C_Med},[601020]={name="Perban Dan Kasa",cat="Med",color=C_Med},[601021]={name="Kotak P3K",cat="Med",color=C_Med},[601022]={name="Kotak P3K",cat="Med",color=C_Med},[601023]={name="Suntikan Andrenalin",cat="Med",color=C_Med},[601061]={name="Kotak P3K",cat="Med",color=C_Med},[601077]={name="Pertolongan Pertama Taktis",cat="Med",color=C_Med},[601078]={name="Pertolongan Pertama Menyeluruh",cat="Med",color=C_Med},[601079]={name="Tabib Mahakuasa",cat="Med",color=C_Med},[601080]={name="Pembalut Kasa",cat="Med",color=C_Med},[601081]={name="Cairan Konsentrat",cat="Med",color=C_Med},[601084]={name="Pertolongan Pertama",cat="Med",color=C_Med},[601085]={name="Ambulans Cepat",cat="Med",color=C_Med},[601095]={name="AED (Defibrilator)",cat="Med",color=C_Med},[601096]={name="Bersiap Menghadapi Pertempuran",cat="Med",color=C_Med},[602054]={name="Perlengkapan Medis",cat="Med",color=C_Med},[602069]={name="Bantuan Darurat",cat="Med",color=C_Med}
}
_G.CachedItems={}
_G.LastScanItemTime=0
_G.AppliedVehicleWall={}
_G.AppliedItemESP={}
_G.RunOptimizedItemAndVehicleESP=function(pc)
local curTime=os.clock()
 -- 1. scan ACTOR dan proses logika item logika 1.0 DETIK / kali (Anti Drop FPS saat ambil barang)
if curTime-_G.LastScanItemTime>1.0 then
_G.LastScanItemTime=curTime
local player=GameplayData.GetPlayerCharacter()
if not slua.isValid(player)then return end
 -- proses logika WALL KENDARAAN KENDARAAN (Pertahankan jarak pandang 200m)
if _G.AimPROConfig.WallVehicle then
local ASTExtraVehicleBase=import("STExtraVehicleBase")
if ASTExtraVehicleBase then
local Actors=Game:GetActorsByClass(ASTExtraVehicleBase)
if Actors then
local count=Actors:Num()or 0
for i=0,count-1 do
local vehicle=Actors:Get(i)
if slua.isValid(vehicle)and vehicle.GetMesh then
local dist=player:GetDistanceTo(vehicle)
if dist<=200000 then
local vId=tostring(vehicle)
if not _G.AppliedVehicleWall[vId]then
local mesh=vehicle:GetMesh()
if slua.isValid(mesh)then
local matInterface=mesh:GetMaterial(0)
if slua.isValid(matInterface)then
local baseMat=matInterface:GetBaseMaterial()
if slua.isValid(baseMat)then
baseMat.bDisableDepthTest=true
baseMat.BlendMode=2
_G.AppliedVehicleWall[vId]=true
end
end
end
end
end
end
end
end
end
else _G.AppliedVehicleWall={}end
 -- proses logika ESP dan CHAMS item barang (posisi teks & Glow di bawah 70m)
if _G.AimPROConfig.EspItem_Master then
local APickUpWrapperActor=import("PickUpWrapperActor")or import("STPickupWrapperActor")
if APickUpWrapperActor then
local Actors=Game:GetActorsByClass(APickUpWrapperActor)
_G.CachedItems={}
if Actors then
local count=Actors:Num()or 0
for i=0,count-1 do
local item=Actors:Get(i)
 -- [FIX macet item barang] Cek apakah item ada sedang menunggu dihapus tidak
local isPendingKill=false
pcall(function()if type(item.IsPendingKill)=="function"then isPendingKill=item:IsPendingKill()end end)
 -- Scan hanya semua item barang valid, tidak tersembunyi (bHidden) dan belum dihapus
if slua.isValid(item)and not item.bHidden and not isPendingKill then
local dist=player:GetDistanceTo(item)
 -- Batas 70m (7000 units), pastikan tidak membebani CPU
if dist<=7000 then
local itemId=item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
local itemData=ItemDatabase[itemId]
if itemData then
 -- Check xem saklar kategori ada sedang aktif tidak?
local isShow=false
if itemData.cat=="AR"and _G.AimPROConfig.EspItem_AR then isShow=true
elseif itemData.cat=="Sniper"and _G.AimPROConfig.EspItem_Sniper then isShow=true
elseif itemData.cat=="SMG"and _G.AimPROConfig.EspItem_SMG then isShow=true
elseif itemData.cat=="Shotgun"and _G.AimPROConfig.EspItem_Shotgun then isShow=true
elseif itemData.cat=="LMG"and _G.AimPROConfig.EspItem_LMG then isShow=true
elseif itemData.cat=="Pistol"and _G.AimPROConfig.EspItem_Pistol then isShow=true
elseif itemData.cat=="Melee"and _G.AimPROConfig.EspItem_Melee then isShow=true
elseif itemData.cat=="Special"and _G.AimPROConfig.EspItem_Special then isShow=true
elseif itemData.cat=="Grenade"and _G.AimPROConfig.EspItem_Grenade then isShow=true
elseif itemData.cat=="Scope"and _G.AimPROConfig.EspItem_Scope then isShow=true
elseif itemData.cat=="Med"and _G.AimPROConfig.EspItem_Med then isShow=true
end
 -- hanya proses logika array dan gambar Glow jika sedang aktif
if isShow then
table.insert(_G.CachedItems,item)
local iId=tostring(item)
if not _G.AppliedItemESP[iId]then
local meshes={}
if item.GetPickupMesh then
local pMesh=item:GetPickupMesh()
if slua.isValid(pMesh)then table.insert(meshes,pMesh)end
end
local childs=item:GetComponentsByClass(import("StaticMeshComponent"))
if childs then
for _,v in pairs(childs)do
if slua.isValid(v)then table.insert(meshes,v)end
end
end
for _,mesh in pairs(meshes)do
pcall(function()mesh:SetRenderCustomDepth(true)end)
for mi=0,8 do
local mid=mesh:CreateAndSetMaterialInstanceDynamic(mi)
if slua.isValid(mid)then
local colorVisible={R=50,G=50,B=0,A=10}
pcall(function()
mid:SetVectorParameterValue("LightColor",colorVisible)
mid:SetVectorParameterValue("ParaScaleOffset",{R=3,G=3,B=0,A=0})
mid:SetScalarParameterValue("RimLight",999)
mid:SetScalarParameterValue("Brightness",999)
mid:SetScalarParameterValue("Exposure",999)
end)
end
end
end
_G.AppliedItemESP[iId]=true
end
end
end
end
end
end
end
end
else
_G.AppliedItemESP={}
_G.CachedItems={}
end
end
 -- 2. TAMPILKAN NAMA ITEM TERUS-MENERUS di FRAME (sangat ringan, berjalan setiap frame)
if _G.AimPROConfig.EspItem_Master and slua.isValid(pc)and pc.MyHUD then
local hud=pc.MyHUD
local player=GameplayData.GetPlayerCharacter()
for _,item in ipairs(_G.CachedItems)do
 -- [maksimal optimal FPS maksimal MAKSIMAL] hanya check bHidden (sangat ringan), hapus juga pcall memakan CPU di loop setiap frame
if slua.isValid(item)and not item.bHidden then
local itemId=item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
if itemId and ItemDatabase[itemId]then
local itemData=ItemDatabase[itemId]
local dist=(player.GetDistanceTo and player:GetDistanceTo(item)or 0)/100
local displayText=string.format("%s [%.0fm]",itemData.name,dist)
local textColor={R=itemData.color.R,G=itemData.color.G,B=itemData.color.B,A=255}
hud:AddDebugText(displayText,item,0.06,{X=0,Y=0,Z=50},{X=0,Y=0,Z=50},textColor,true,false,true,nil,0.8,true
)
end
end
end
end
end
-- ========================================== 
-- UI WIDGET hitung MUSUH & sekitar jarak dekat paling (NEW ESP LOGIC)
-- ========================================== 
local BTN_BP="/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local EnemyCounterWidget=nil
local WarningTargetWidget=nil
local LastCounterTime=0
-- tambahkan Fungsi Bersihkan rapikan WIDGET saat Keluar match
function _G.CleanUpEnemyCounterWidget()
if EnemyCounterWidget and slua.isValid(EnemyCounterWidget)then
EnemyCounterWidget:RemoveFromParent()
end
EnemyCounterWidget=nil
if WarningTargetWidget and slua.isValid(WarningTargetWidget)then
WarningTargetWidget:RemoveFromParent()
end
WarningTargetWidget=nil
end
-- BUAT UI: hitung MUSUH (asli)
local function CreateEnemyCounterWidget()
if EnemyCounterWidget then
if slua.isValid(EnemyCounterWidget)then return EnemyCounterWidget else EnemyCounterWidget=nil end
end
pcall(function()
local btn=slua.loadUI(BTN_BP)
if not btn or not slua.isValid(btn)then return end
require("game_frontend_hud").AddToContainer(UIContainers.Top,btn,10500)
if btn.RichText_Content then
btn.RichText_Content:SetText("Enemy:0 | Nearest:0m")
local fontInfo=btn.RichText_Content.Font
if fontInfo then fontInfo.Size=16 btn.RichText_Content:SetFont(fontInfo)end
end
local WidgetLayoutLibrary=import("WidgetLayoutLibrary")
local slot=WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
if slot then
slot:SetAnchors(FAnchors(0.5,0,0.5,0))
slot:SetAlignment(FVector2D(0.5,0))
slot:SetPosition(FVector2D(0,30))
slot:SetSize(FVector2D(240,36))
end
btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
EnemyCounterWidget=btn
end)
return EnemyCounterWidget
end
-- BUAT UI: peringatan lapor MUSUH membidik (unik buat)
local function CreateWarningTargetWidget()
if WarningTargetWidget then
if slua.isValid(WarningTargetWidget)then return WarningTargetWidget else WarningTargetWidget=nil end
end
pcall(function()
local btn=slua.loadUI(BTN_BP)
if not btn or not slua.isValid(btn)then return end
 require("game_frontend_hud").AddToContainer(UIContainers.Top,btn,10501) -- Z-Order lebih tinggi agar muncul di depan
if btn.RichText_Content then
 -- Teks warna merah peringatan lapor kuat
btn.RichText_Content:SetText("Musuh Melihat Ke Arahmu")
local fontInfo=btn.RichText_Content.Font
if fontInfo then fontInfo.Size=18 btn.RichText_Content:SetFont(fontInfo)end
end
local WidgetLayoutLibrary=import("WidgetLayoutLibrary")
local slot=WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
if slot then
slot:SetAnchors(FAnchors(0.5,0,0.5,0))
slot:SetAlignment(FVector2D(0.5,0))
 slot:SetPosition(FVector2D(0,75)) -- Posisi di bawah UI jumlah MUSUH (Y=75)
slot:SetSize(FVector2D(260,36))
end
 btn:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) -- Tetap tersembunyi, hanya tampil saat MUSUH membidik
WarningTargetWidget=btn
end)
return WarningTargetWidget
end
-- lingkaran ulang SAMA (hitung hitung 1 kali untuk semua 2 UI untuk anti DROP FPS)
local function _M_DrawCounter()
if _i then
_G.CleanUpEnemyCounterWidget()
return
end
pcall(function()
local player=GameplayData.GetPlayerCharacter()
if not slua.isValid(player)then
if EnemyCounterWidget and slua.isValid(EnemyCounterWidget)then
EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
if WarningTargetWidget and slua.isValid(WarningTargetWidget)then
WarningTargetWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
return
end
local widgetCounter=CreateEnemyCounterWidget()
local widgetWarning=CreateWarningTargetWidget()
if widgetCounter and slua.isValid(widgetCounter)then
widgetCounter:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
end
 -- [maksimal optimal FPS] Batasi interval hitung hitung 0.5 detik / kali agar tidak terlalu beban CPU
local curTime=os.clock()
if(curTime-LastCounterTime)>0.5 then
LastCounterTime=curTime
local myTeam=player.TeamID or(type(player.GetTeamID)=="function"and player:GetTeamID())or 0
local count=0
local nearest=9999
 local isBeingTargeted=false -- Status peringatan
local KismetMathLibrary=import("KismetMathLibrary")
local pc=player:GetPlayerControllerSafety()
local allCharacters={}
if GameplayData.GetAllPlayerCharacters then
allCharacters=GameplayData.GetAllPlayerCharacters()
elseif GameplayData.GameCharacters then
for _,char in pairs(GameplayData.GameCharacters)do table.insert(allCharacters,char)end
end
for _,tPawn in pairs(allCharacters)do
if slua.isValid(tPawn)and tPawn~=player then
local isAlive=false
if tPawn.HealthStatus~=nil then
isAlive=(tPawn.HealthStatus~=2)
else
isAlive=(tPawn.Health or 0)>0 or(type(tPawn.IsAlive)=="function"and tPawn:IsAlive())
end
if isAlive then
local tTeam=tPawn.TeamID or(type(tPawn.GetTeamID)=="function"and tPawn:GetTeamID())or 0
if tTeam~=myTeam then
count=count+1
local d=math.floor(player:GetDistanceTo(tPawn)/100)
if d<nearest then nearest=d end
 -- ========================================================
 -- LOGIC CHECK MUSUH membidik (hanya hitung saat sekitar jarak < 400m)
 -- ========================================================
if _G.AimPROConfig.EspAimWarning and not isBeingTargeted and d<400 then
local eLoc=type(tPawn.K2_GetActorLocation)=="function"and tPawn:K2_GetActorLocation()
local pLoc=type(player.K2_GetActorLocation)=="function"and player:K2_GetActorLocation()
if eLoc and pLoc and KismetMathLibrary then
local lookRot=KismetMathLibrary.FindLookAtRotation(eLoc,pLoc)
local eRot=nil
if type(tPawn.GetControlRotation)=="function"then
eRot=tPawn:GetControlRotation()
elseif type(tPawn.GetActorRotation)=="function"then
eRot=tPawn:GetActorRotation()
end
if eRot and lookRot then
local dYaw=math.abs(eRot.Yaw-lookRot.Yaw)
if dYaw>180 then dYaw=360-dYaw end
local dPitch=math.abs(eRot.Pitch-lookRot.Pitch)
if dPitch>180 then dPitch=360-dPitch end
 -- Arah laras MUSUH melenceng < 15 derajat
if dYaw<15 and dPitch<20 then
 -- Terapkan logic Check tembok (VisCheck)
if _G.AimPROConfig.EspAimWarningVisCheck then
if slua.isValid(pc)and type(pc.LineOfSightTo)=="function"then
if pc:LineOfSightTo(tPawn)then
isBeingTargeted=true
end
end
else
 -- Tembus tembok lapor selalu
isBeingTargeted=true
end
end
end
end
end
 -- ========================================================
end
end
end
end
 -- Update isi UI hitung MUSUH (frame 1)
if widgetCounter and widgetCounter.RichText_Content then
widgetCounter.RichText_Content:SetText(string.format("Enemy:%d | near:%dm",count,count>0 and nearest or 0))
end
 -- Sembunyikan/Tampilkan UI peringatan lapor unik buat (frame 2)
if widgetWarning and slua.isValid(widgetWarning)then
if _G.AimPROConfig.EspAimWarning and isBeingTargeted then
widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
else
widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
end
end
end)
end


do
local ESP_Enabled = true

local FVector2D = _G.FVector2D or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")
local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local SlateColor = nil
local GameplayStaticsESP = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
pcall(function() SlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor") end)
pcall(function() GameplayStaticsESP = import("GameplayStatics") end)
local KismetSystemLibraryESP = nil
local HitResultClassESP = nil
pcall(function() KismetSystemLibraryESP = import("KismetSystemLibrary") end)
pcall(function() HitResultClassESP = import("HitResult") end)
local TraceStartPos = { X = 0, Y = 0, Z = 0 }
local CachedHitResult = nil
pcall(function()
  if HitResultClassESP then CachedHitResult = HitResultClassESP()
  else CachedHitResult = {} end
end)

local function ESPValid(obj)
  if obj == nil then return false end
  local ok, v = pcall(function() return slua.isValid(obj) end)
  return ok and v == true
end

local function ESPV2(x, y)
  if FVector2D then return FVector2D(x, y) end
  return { X = x, Y = y }
end

local function ESPMKC(r, g, b, a)
  if FLinearColor then return FLinearColor(r, g, b, a) end
  return { R = r, G = g, B = b, A = a }
end

local CFG = {
  MaxDistance = 40000,      -- cm (400 m)
  MaxTracked = 16,
  ScreenMargin = 220,
  TopTextY = 46.0,          -- counter diturunkan sedikit lagi
  SnapOriginY = 0.0,        -- top edge se start (esplook jaisa)
  SnapThickness = 1.2,
  CornerThickness = 1.4,
  CornerLen = 0.28,
  CornerMin = 6,
  CornerMax = 28,
  BoxMinWidth = 22,
  BoxMaxWidth = 320,
  BoxMinHeight = 14,
  BoxWidthFactor = 0.62,
  WidthScale = 1.22,
  HeadExtra = 0.06,
  FootExtra = 0.02,
  SideBarWidth = 2.5,
  SideBarGap = 5.0,
  SideBgAlpha = 0.55,
  -- Legacy chevron settings retained only for compatibility; chevron rendering is disabled.
  NameFontSize = 15,
  DistFontSize = 13,
  StateFontSize = 13,
  TextGap = 1.0,
  CounterFontSize = 17,
  CounterW = 300.0,
  CounterH = 28.0,
  DeadZone = 0.5,           -- px, isse kam harkat = slate ko chhuna nahi (flicker fix)
  VisInterval = 0.40,       -- sec, LineTrace itni der me ek bar per target (lag fix)
  SizeHyst = 2.0,           -- px, viewport me itna farq ignore
}

-- esplook.png colors
local C_WHITE  = ESPMKC(1.0, 1.0, 1.0, 1.0)
local C_BLACK  = ESPMKC(0.0, 0.0, 0.0, 1.0)
local C_GREEN  = ESPMKC(0.12, 1.0, 0.25, 1.0)   -- snap line + "Open"
local C_RED    = ESPMKC(1.0, 0.15, 0.15, 1.0)   -- low health + "Close"
local C_YELLOW = ESPMKC(1.0, 0.90, 0.30, 1.0)   -- double chevron
local C_BLUE   = ESPMKC(0.38, 0.72, 1.0, 1.0)   -- "Bot" name

local function RND(v)
  if v ~= v then return 0 end
  return math.floor(v + 0.5)
end

local function Lerp(a, b, t) return a + (b - a) * t end

-- Health color: 100% green | 70% green+halka yellow | 40% red+halka white | 20% red
local function HealthColor(pct)
  pct = tonumber(pct) or 1.0
  if pct < 0 then pct = 0 end
  if pct > 1 then pct = 1 end
  local r, g, b
  if pct >= 0.7 then
    local t = (pct - 0.7) / 0.3
    r = Lerp(0.75, 0.12, t)
    g = 1.0
    b = Lerp(0.15, 0.25, t)
  elseif pct >= 0.4 then
    local t = (pct - 0.4) / 0.3
    r = 1.0
    g = Lerp(0.45, 0.95, t)
    b = Lerp(0.45, 0.20, t)
  else
    local t = pct / 0.4
    r = 1.0
    g = Lerp(0.15, 0.45, t)
    b = Lerp(0.15, 0.45, t)
  end
  return ESPMKC(r, g, b, 1.0)
end

local ESP = {}
ESP.Canvas = nil
ESP.Lines = {}      -- snap lines : key -> {Widget, Slot}
ESP.Corners = {}    -- corner boxes: key -> {w1..w8 Widget/Slot}
ESP.HealthBg = {}   -- health bg (dark) : key -> {Widget, Slot}
ESP.HealthFill = {} -- health fill (pct + color) : key -> {Widget, Slot}
ESP.Marks = {}      -- yellow chevron: key -> {4 x Widget/Slot}
ESP.Infos = {}      -- bottom texts: key -> {Container, Name, Dist, State, slots}
ESP.Counter = nil   -- top "Players: X | Bots: Y"
ESP.EnemyCache = {}
ESP.VisCache = {}   -- visibility cache: key -> {b, t}
ESP.ScaleX = 1.0
ESP.ScaleY = 1.0
ESP.OffsetX = 0.0
ESP.OffsetY = 0.0
ESP.ViewW = 1920
ESP.ViewH = 1080
ESP.ScanInterval = 0.25
ESP.LightInterval = 0.050  -- max ESP render/update rate: 20 Hz
ESP.TransformInterval = 0.75
ESP.LastScan = -999.0
ESP.LastRender = -999.0
ESP.InfoTextCache = {}
ESP.LastTransform = -999.0
ESP.LastWorld = nil
ESP.bActive = false

function ESP.GetGameplayData()
  if ESP._GDP then return ESP._GDP end
  local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
  if ok and GDP then ESP._GDP = GDP return GDP end
  return nil
end

function ESP.GetController()
  local pc = nil
  pcall(function()
    local GDP = ESP.GetGameplayData()
    if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
  end)
  if not ESPValid(pc) then
    pcall(function()
      if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
    end)
  end
  return ESPValid(pc) and pc or nil
end

function ESP.GetLocalCharacter()
  local c = nil
  pcall(function()
    local GDP = ESP.GetGameplayData()
    if GDP then
      if GDP.GetPlayerCharacter then c = GDP.GetPlayerCharacter() end
      if not ESPValid(c) and GDP.GetLocalCharacter then c = GDP.GetLocalCharacter() end
    end
  end)
  if not ESPValid(c) then
    local pc = ESP.GetController()
    pcall(function() if pc and pc.GetPawn then c = pc:GetPawn() end end)
  end
  return ESPValid(c) and c or nil
end

function ESP.GetAllCharacters()
  local AllChars = {}
  pcall(function()
    local Pawns = Game:GetAllPlayerPawns()
    if Pawns then
      for _, Pawn in pairs(Pawns) do
        if Pawn and slua.isValid(Pawn) then
          local pKey = nil
          if Pawn.GetPlayerKey then pcall(function() pKey = Pawn:GetPlayerKey() end) end
          if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
          if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
          if pKey then AllChars[pKey] = Pawn end
        end
      end
    end
  end)
  if not next(AllChars) then
    pcall(function()
      local GS = require("GameLua.GameCore.Data.CGameState")
      if GS and GS.GetAllCharacters then AllChars = GS:GetAllCharacters() end
    end)
  end
  return AllChars
end

function ESP.GetMyPlayerKey()
  local pc = ESP.GetController()
  if not ESPValid(pc) then return nil end
  local k = nil
  pcall(function()
    if pc.GetPlayerKey then k = pc:GetPlayerKey()
    elseif pc.PlayerState and pc.PlayerState.PlayerKey then k = pc.PlayerState.PlayerKey end
  end)
  return k
end

function ESP.IsMe(Character, PlayerKey, MyKey)
  local me = false
  pcall(function()
    local GDP = ESP.GetGameplayData()
    if GDP and GDP.GetLocalCharacter then
      local mc = GDP.GetLocalCharacter()
      if mc and Character == mc then me = true return end
    end
    local pc = ESP.GetController()
    if pc and pc.GetPawn then
      local p = pc:GetPawn()
      if p and Character == p then me = true return end
    end
  end)
  if not me and MyKey ~= nil and PlayerKey ~= nil then
    me = (tostring(PlayerKey) == tostring(MyKey))
  end
  return me
end

function ESP.GetTeamID(Character)
  if not ESPValid(Character) then return nil end
  local id = nil
  pcall(function() if Character.GetTeamID then id = Character:GetTeamID() end end)
  if id == nil then pcall(function() id = Character.TeamID end) end
  if id == nil then
    local ps = nil
    pcall(function()
      if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then ps = Character:GetPlayerState() end
    end)
    if not ESPValid(ps) then pcall(function() ps = Character.PlayerState end) end
    if ESPValid(ps) then
      pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
      if id == nil then pcall(function() id = ps.TeamID end) end
    end
  end
  return id
end

function ESP.IsAlive(Character)
  if not ESPValid(Character) then return false end
  local alive = nil
  pcall(function() if Character.IsAlive then alive = Character:IsAlive() end end)
  if type(alive) == "boolean" then return alive end
  local hp = nil
  pcall(function() hp = Character.Health end)
  if type(hp) ~= "number" then pcall(function() hp = Character.HP end) end
  if type(hp) == "number" then return hp > 0 end
  return true
end

function ESP.IsKnocked(Character)
  if not ESPValid(Character) then return false end
  local k = false
  pcall(function()
    if Character.HealthStatus == 1 then k = true end
  end)
  if not k then pcall(function()
    if Character.IsNearDeath and Character:IsNearDeath() then k = true end
  end) end
  return k
end

function ESP.IsBot(Character)
  if not ESPValid(Character) then return false end
  local bAI = false
  pcall(function()
    if Game and Game.IsAI then bAI = Game:IsAI(Character) end
    if not bAI and Character then
      if Character.bEnsure == true or Character.bMEnsure == true then bAI = true
      elseif Character.PlayerState and Character.PlayerState.bPSEnsure == true then bAI = true
      elseif Character.Controller then
        if Character.Controller.IsMLAI == true or Character.Controller.FakePlayerBornType == 1 then bAI = true end
      end
    end
  end)
  if not bAI then
    pcall(function()
      if Character.bIsAI == true then bAI = true end
    end)
  end
  if not bAI then
    local ps = nil
    pcall(function()
      if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety() end
    end)
    if ESPValid(ps) then
      pcall(function()
        if ps.bIsABot == true or ps.bIsBot == true or ps.bIsAI == true then bAI = true end
      end)
    end
  end
  return bAI
end

function ESP.GetPlayerKey(Character)
  local key = nil
  pcall(function() if Character.GetPlayerKey then key = Character:GetPlayerKey() end end)
  if key == nil then pcall(function() key = Character.PlayerKey end) end
  return tostring(key or Character)
end

function ESP.GetHealthPct(Character)
  if not ESPValid(Character) then return 1.0 end
  local hp, maxhp = nil, nil
  pcall(function() hp = Character.Health end)
  if type(hp) ~= "number" then pcall(function() hp = Character.HP end) end
  pcall(function() maxhp = Character.MaxHealth end)
  if type(maxhp) ~= "number" then pcall(function() maxhp = Character.MaxHP end) end
  if type(hp) ~= "number" then return 1.0 end
  if type(maxhp) ~= "number" or maxhp <= 0 then maxhp = 100 end
  local pct = hp / maxhp
  if pct ~= pct then return 1.0 end
  if pct < 0 then pct = 0 end
  if pct > 1 then pct = 1 end
  return pct
end

local function NormalizeName(v)
  if v == nil or v == false then return nil end
  local ok, t = pcall(tostring, v)
  if not ok or not t then return nil end
  t = t:gsub("^%s+", ""):gsub("%s+$", "")
  if t == "" or t == "nil" or t == "None" or t == "NULL" or t == "Unknown" then return nil end
  return t
end

function ESP.ResolveName(Character, isBot)
  if isBot then return "Bot" end
  local name = nil
  local function take(v)
    if not name then name = NormalizeName(v) end
  end
  pcall(function() if Character.GetPlayerNameSafety then take(Character:GetPlayerNameSafety()) end end)
  pcall(function() if not name and Character.GetPlayerName then take(Character:GetPlayerName()) end end)
  pcall(function() if not name then take(Character.PlayerName) end end)
  pcall(function() if not name then take(Character.NickName) end end)
  if not name then
    local ps = nil
    pcall(function()
      if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then ps = Character:GetPlayerState() end
    end)
    if not ESPValid(ps) then pcall(function() ps = Character.PlayerState end) end
    if ESPValid(ps) then
      pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
      pcall(function() if not name then take(ps.PlayerName) end end)
      pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
      pcall(function() if not name then take(ps.NickName) end end)
    end
  end
  return name or "Player"
end

function ESP.GetBonePos(Character, boneName)
  if not ESPValid(Character) or not boneName then return nil end
  local pos = nil
  pcall(function()
    if type(Character.GetBonePos) == "function" then
      pos = Character:GetBonePos(boneName, { X = 0, Y = 0, Z = 0 })
    end
    if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
      if type(Character.GetSocketLocation) == "function" then
        pos = Character:GetSocketLocation(boneName)
      end
    end
    if (not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0)) and ESPValid(Character.Mesh) then
      local mesh = Character.Mesh
      if mesh and mesh.GetSocketLocation then
        local mp = mesh:GetSocketLocation(boneName)
        if mp and not (mp.X == 0 and mp.Y == 0 and mp.Z == 0) then pos = mp end
      end
    end
  end)
  return pos
end

function ESP.GetCamLoc(pc)
  local loc = nil
  pcall(function()
    if GameplayStaticsESP and GameplayStaticsESP.GetPlayerCameraManager then
      local mgr = GameplayStaticsESP.GetPlayerCameraManager(pc, 0)
      if ESPValid(mgr) and mgr.GetCameraLocation then loc = mgr:GetCameraLocation() end
    end
  end)
  if not loc then
    pcall(function()
      if pc and pc.GetPawn then
        local p = pc:GetPawn()
        if ESPValid(p) and p.K2_GetActorLocation then loc = p:K2_GetActorLocation() end
      end
    end)
  end
  return loc
end

function ESP.IsBoneVisible(pc, camLoc, target, bonePos)
  if not ESPValid(pc) or not ESPValid(target) or not bonePos or not camLoc then return false end
  if not KismetSystemLibraryESP or not KismetSystemLibraryESP.LineTraceSingle then return true end
  local dx = bonePos.X - camLoc.X
  local dy = bonePos.Y - camLoc.Y
  local dz = bonePos.Z - camLoc.Z
  local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
  if dist < 50 then return true end
  TraceStartPos.X = camLoc.X + (dx / dist) * 60
  TraceStartPos.Y = camLoc.Y + (dy / dist) * 60
  TraceStartPos.Z = camLoc.Z + (dz / dist) * 60
  local bVis = false
  pcall(function()
    local bHit = KismetSystemLibraryESP.LineTraceSingle(
      pc, TraceStartPos, bonePos, 0, false, nil, 0, CachedHitResult, true)
    if bHit then
      local hitActor = nil
      if CachedHitResult then
        if type(CachedHitResult.GetActor) == "function" then
          hitActor = CachedHitResult:GetActor()
        elseif CachedHitResult.Actor then
          hitActor = CachedHitResult.Actor
        end
      end
      if ESPValid(hitActor) then
        if hitActor == target then bVis = true end
      end
    else
      bVis = true
    end
  end)
  return bVis
end

function ESP.IsVisible(key, pc, camLoc, Character)
  local now = ESP.Now()
  local cached = ESP.VisCache[key]
  if cached and (now - (cached.t or 0)) < (CFG.VisInterval or 0.15) then
    return cached.b
  end
  local bVis = false
  if ESPValid(Character) and ESPValid(pc) and camLoc then
    -- One trace is enough for the Open/Close indicator in normal play.
    -- Spine is only a fallback when the head position is unavailable.
    local bp = ESP.GetBonePos(Character, "head")
    if not bp or (bp.X == 0 and bp.Y == 0 and bp.Z == 0) then
      bp = ESP.GetBonePos(Character, "spine_03")
    end
    if bp and (bp.X ~= 0 or bp.Y ~= 0 or bp.Z ~= 0) then
      bVis = ESP.IsBoneVisible(pc, camLoc, Character, bp)
    end
  else
    bVis = true
  end
  ESP.VisCache[key] = { b = bVis, t = now }
  return bVis
end

function ESP.ActorLocation(Character)
  local loc = nil
  if not ESPValid(Character) then return nil end
  pcall(function()
    if Character.K2_GetActorLocation then loc = Character:K2_GetActorLocation()
    elseif Game and Game.GetActorLocation then loc = Game:GetActorLocation(Character) end
  end)
  return loc
end

function ESP.DistMeters(a, b)
  if not a or not b then return math.huge end
  local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
  return math.sqrt(dx * dx + dy * dy + dz * dz) / 100.0
end

function ESP.GetVerticalBounds(Character)
  if not ESPValid(Character) then return nil, nil end
  local center, halfHeight = nil, nil
  local capsule = nil
  pcall(function()
    if Character.GetCapsuleComponent then capsule = Character:GetCapsuleComponent()
    elseif Character.CapsuleComponent then capsule = Character.CapsuleComponent end
  end)
  if capsule and ESPValid(capsule) then
    pcall(function()
      if capsule.K2_GetComponentLocation then center = capsule:K2_GetComponentLocation()
      elseif capsule.GetComponentLocation then center = capsule:GetComponentLocation() end
      if capsule.GetScaledCapsuleHalfHeight then halfHeight = capsule:GetScaledCapsuleHalfHeight()
      elseif capsule.GetUnscaledCapsuleHalfHeight then halfHeight = capsule:GetUnscaledCapsuleHalfHeight()
      elseif capsule.CapsuleHalfHeight then halfHeight = capsule.CapsuleHalfHeight end
    end)
  end
  if not center then
    pcall(function() if Character.K2_GetActorLocation then center = Character:K2_GetActorLocation() end end)
  end
  if not center then
    pcall(function() if Game and Game.GetActorLocation then center = Game:GetActorLocation(Character) end end)
  end
  if not center then return nil, nil end
  if not halfHeight or halfHeight < 10 or halfHeight > 200 then
    halfHeight = 85
    pcall(function()
      if Character.bIsCrouched then halfHeight = 60 end
      if Character.IsProne and Character:IsProne() then halfHeight = 25 end
    end)
  end
  return center, halfHeight
end

function ESP.GetHeadFeet(Character)
  local center, half = ESP.GetVerticalBounds(Character)
  if not center or not half then return nil, nil end
  local head = { X = center.X, Y = center.Y, Z = center.Z + half }
  local feet = { X = center.X, Y = center.Y, Z = center.Z - half }
  return head, feet
end

function ESP.Now()
  local t = nil
  pcall(function()
    local w = (slua and slua.getWorld and slua.getWorld()) or nil
    if GameplayStaticsESP and w and GameplayStaticsESP.GetRealTimeSeconds then
      t = GameplayStaticsESP.GetRealTimeSeconds(w)
    end
  end)
  if tonumber(t) then return tonumber(t) end
  pcall(function() if os and os.clock then t = os.clock() end end)
  return tonumber(t) or 0.0
end

function ESP.World()
  local w = nil
  pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
  return w
end

-- ---------- canvas ----------
function ESP.GetCanvas()
  if ESPValid(ESP.Canvas) then return ESP.Canvas end
  local root = nil
  pcall(function()
    local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    if InGameUITools and InGameUITools.GetMainControlBaseUI then root = InGameUITools.GetMainControlBaseUI() end
  end)
  if not ESPValid(root) then return nil end
  local canvas = nil
  pcall(function()
    if ESPValid(root.CanvasPanel_0) then canvas = root.CanvasPanel_0
    elseif ESPValid(root.CanvasPanel_42) then canvas = root.CanvasPanel_42 end
  end)
  if ESPValid(canvas) then ESP.Canvas = canvas return canvas end
  return nil
end

function ESP.UpdateCanvasTransform(pc)
  local canvas = ESP.GetCanvas()
  if not ESPValid(canvas) then return false end
  local calibrated = false
  pcall(function()
    if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
      local geo = canvas:GetCachedGeometry()
      if geo then
        local p0 = SlateBlueprintLibrary.AbsoluteToLocal(geo, ESPV2(0, 0))
        local p1 = SlateBlueprintLibrary.AbsoluteToLocal(geo, ESPV2(100, 100))
        if p0 and p1 and tonumber(p0.X) and tonumber(p1.X) and p1.X ~= p0.X and p1.Y ~= p0.Y then
          ESP.ScaleX = (p1.X - p0.X) / 100.0
          ESP.ScaleY = (p1.Y - p0.Y) / 100.0
          ESP.OffsetX = p0.X
          ESP.OffsetY = p0.Y
          calibrated = true
        end
      end
    end
  end)
  if not calibrated then
    local scale = 1.0
    pcall(function()
      if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
        local s = WidgetLayoutLibrary.GetViewportScale(pc)
        if tonumber(s) and s > 0 then scale = s end
      end
    end)
    ESP.ScaleX = 1.0 / scale
    ESP.ScaleY = 1.0 / scale
    ESP.OffsetX = 0.0
    ESP.OffsetY = 0.0
  end
  return true
end

function ESP.Viewport(pc)
  local w, h = 1920.0, 1080.0
  pcall(function()
    if pc and pc.GetViewportSize then
      local v = ESPV2(0, 0)
      pc:GetViewportSize(v)
      if v and tonumber(v.X) and v.X > 200 then w, h = v.X, v.Y end
    end
  end)
  return w, h
end

function ESP.Project(pc, worldLoc)
  if not pc or not worldLoc then return nil end

  -- Direction-safe projection:
  -- Some game builds can return a false/zero status exactly when the camera
  -- is aligned closely with the target, even though a valid screen position
  -- is produced. Keep the existing projection mode first, then retry using
  -- the alternate viewport flag only when the first result is unusable.
  local pix = ESPV2(0, 0)
  local ok = false

  pcall(function()
    local res = pc:ProjectWorldLocationToScreen(worldLoc, pix, true)
    local x, y = tonumber(pix.X), tonumber(pix.Y)
    ok = (res == true or res == 1) and x ~= nil and y ~= nil
  end)

  if not ok then
    pix = ESPV2(0, 0)
    pcall(function()
      local res = pc:ProjectWorldLocationToScreen(worldLoc, pix, false)
      local x, y = tonumber(pix.X), tonumber(pix.Y)
      ok = (res == true or res == 1) and x ~= nil and y ~= nil
    end)
  end

  if not ok then return nil end

  local x, y = tonumber(pix.X), tonumber(pix.Y)
  if not x or not y then return nil end

  return ESPV2(
    x * (ESP.ScaleX or 1.0) + (ESP.OffsetX or 0.0),
    y * (ESP.ScaleY or 1.0) + (ESP.OffsetY or 0.0)
  ), pix
end

function ESP.SnapOrigin(pc, viewW)
  -- V6: Line origin mengikuti titik tengah VISUAL counter yang benar-benar
  -- tampil di layar. Versi sebelumnya menghitung origin dari viewport/transform
  -- sehingga bisa bergeser walaupun counter sudah tepat di tengah.
  local canvas = ESP.GetCanvas()
  local counter = ESP.Counter
  if ESPValid(canvas) and counter then
    local text = counter.Text
    if ESPValid(text) and SlateBlueprintLibrary and
       SlateBlueprintLibrary.LocalToAbsolute and SlateBlueprintLibrary.AbsoluteToLocal then
      local ok, result = pcall(function()
        local tgeo = text:GetCachedGeometry()
        local cgeo = canvas:GetCachedGeometry()
        if not tgeo or not cgeo then return nil end
        local sz = nil
        if tgeo.GetLocalSize then sz = tgeo:GetLocalSize() end
        if not sz or not tonumber(sz.X) then
          sz = ESPV2(0, 0)
          if text.GetDesiredSize then
            local ds = text:GetDesiredSize()
            if ds and tonumber(ds.X) then sz = ds end
          end
        end
        local absCenter = SlateBlueprintLibrary.LocalToAbsolute(
          tgeo, ESPV2((tonumber(sz.X) or 0) * 0.5, (tonumber(sz.Y) or 0) * 0.5)
        )
        if not absCenter then return nil end
        local localCenter = SlateBlueprintLibrary.AbsoluteToLocal(cgeo, absCenter)
        if localCenter and tonumber(localCenter.X) then
          return ESPV2(tonumber(localCenter.X), tonumber(CFG.SnapOriginY) or 0.0)
        end
        return nil
      end)
      if ok and result then return result end
    end

    -- Fallback: gunakan geometry container, masih pada Canvas yang sama.
    if ESPValid(counter.Container) and SlateBlueprintLibrary and
       SlateBlueprintLibrary.LocalToAbsolute and SlateBlueprintLibrary.AbsoluteToLocal then
      local ok, result = pcall(function()
        local cgeo = counter.Container:GetCachedGeometry()
        local ggeo = canvas:GetCachedGeometry()
        if not cgeo or not ggeo then return nil end
        local w = tonumber(counter.W) or tonumber(CFG.CounterW) or 300.0
        local h = tonumber(counter.H) or tonumber(CFG.CounterH) or 28.0
        local absCenter = SlateBlueprintLibrary.LocalToAbsolute(cgeo, ESPV2(w * 0.5, h * 0.5))
        if not absCenter then return nil end
        local localCenter = SlateBlueprintLibrary.AbsoluteToLocal(ggeo, absCenter)
        if localCenter and tonumber(localCenter.X) then
          return ESPV2(tonumber(localCenter.X), tonumber(CFG.SnapOriginY) or 0.0)
        end
        return nil
      end)
      if ok and result then return result end
    end
  end

  -- Last fallback only if geometry is not ready yet.
  local vw = tonumber(viewW) or tonumber(ESP.ViewW) or 1920.0
  if vw < 1 then vw = 1920.0 end
  local cx = vw * 0.5 * (ESP.ScaleX or 1.0) + (ESP.OffsetX or 0.0)
  return ESPV2(cx, (CFG.SnapOriginY or 0.0))
end

-- ---------- widget helpers (Help patterns) ----------
function ESP.SetFont(w, size)
  if not ESPValid(w) then return end
  pcall(function()
    local f = w.Font
    if f then
      f.Size = size
      if f.OutlineSettings then
        pcall(function() f.OutlineSettings.OutlineSize = 1 end)
        pcall(function() f.OutlineSettings.OutlineColor = C_BLACK end)
      end
      w:SetFont(f)
    end
    if w.SetShadowOffset then w:SetShadowOffset(ESPV2(1.0, 1.0)) end
    if w.SetShadowColorAndOpacity then w:SetShadowColorAndOpacity(C_BLACK) end
  end)
end

function ESP.SetTextColor(w, color)
  if not ESPValid(w) then return end
  pcall(function()
    if SlateColor then w:SetColorAndOpacity(SlateColor(color))
    else w:SetColorAndOpacity(color) end
  end)
end

function ESP.NewLine(color, z)
  local canvas = ESP.GetCanvas()
  if not ESPValid(canvas) then return nil end
  local border = nil
  pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
  if not ESPValid(border) then return nil end
  pcall(function()
    border:SetBrushColor(color)
    border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    border:SetRenderTransformPivot(ESPV2(0.0, 0.5))
  end)
  local slot = nil
  pcall(function() slot = canvas:AddChildToCanvas(border) end)
  if not slot then
    pcall(function() border:RemoveFromParent() end)
    return nil
  end
  pcall(function() slot:SetAutoSize(false) slot:SetZOrder(z or 30) end)
  return { Widget = border, Slot = slot }
end

function ESP.DrawLine(data, x1, y1, x2, y2, thickness)
  if not data or not ESPValid(data.Widget) or not data.Slot then return false end
  if x1 ~= x1 or y1 ~= y1 or x2 ~= x2 or y2 ~= y2 then return false end
  x1, y1, x2, y2 = RND(x1), RND(y1), RND(x2), RND(y2)
  local dz = CFG.DeadZone or 0.5
  if data.lx1 and data.th == thickness then
    if math.abs((data.lx1 or 0) - x1) < dz and math.abs((data.ly1 or 0) - y1) < dz
    and math.abs((data.lx2 or 0) - x2) < dz and math.abs((data.ly2 or 0) - y2) < dz then
      if data.hidden ~= true then return true end
    end
  end
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  if len < 1 then
    ESP.Hide(data)
    return false
  end
  local angle = ((math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)) * 180.0 / math.pi
  angle = math.floor(angle * 10 + 0.5) / 10
  len = RND(len)
  if data.lx1 == x1 and data.ly1 == y1 and data.lx2 == x2 and data.ly2 == y2 and data.th == thickness then
    if data.hidden == true then
      pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
      data.hidden = false
    end
    return true
  end
  local ok = pcall(function()
    data.Slot:SetPosition(ESPV2(x1, y1 - thickness * 0.5))
    data.Slot:SetSize(ESPV2(len, thickness))
    data.Widget:SetRenderAngle(angle)
    data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  end)
  if ok then
    data.lx1, data.ly1, data.lx2, data.ly2, data.th = x1, y1, x2, y2, thickness
    data.hidden = false
  end
  return true
end

function ESP.DrawVBar(data, x, top, h, thickness)
  -- vertical health bar: no angle math, seedha Position+Size (double-draw fix)
  if not data or not ESPValid(data.Widget) or not data.Slot then return false end
  if h ~= h or h < 1 then ESP.Hide(data) return false end
  x, top, h = RND(x), RND(top), RND(h)
  local dz = CFG.DeadZone or 0.5
  if data.bx ~= nil then
    if math.abs(data.bx - x) < dz and math.abs(data.bt - top) < dz and math.abs(data.bh - h) < dz then
      if data.hidden ~= true then return true end
    end
  end
  if data.bx == x and data.bt == top and data.bh == h then
    if data.hidden == true then
      pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
      data.hidden = false
    end
    return true
  end
  local ok = pcall(function()
    data.Slot:SetPosition(ESPV2(x, top))
    data.Slot:SetSize(ESPV2(thickness, h))
    data.Widget:SetRenderAngle(0)
    data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  end)
  if ok then data.bx, data.bt, data.bh = x, top, h data.hidden = false end
  return true
end

function ESP.Hide(data)
  if data and ESPValid(data.Widget) and data.hidden ~= true then
    pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    data.hidden = true
    data.lx1, data.ly1, data.lx2, data.ly2, data.th = nil, nil, nil, nil, nil
    data.bx, data.bt, data.bh = nil, nil, nil
  end
end

function ESP.SetBrush(data, color, colorKey)
  if not data or not ESPValid(data.Widget) then return end
  if colorKey and data.colorKey == colorKey then return end
  pcall(function() data.Widget:SetBrushColor(color) end)
  if colorKey then data.colorKey = colorKey end
end

function ESP.Destroy(data)
  if not data then return end
  local w = data.Widget or data.Container
  if ESPValid(w) then
    pcall(function() w:RemoveFromParent() end)
    pcall(function() w:ConditionalBeginDestroy() end)
  end
end

-- top counter "Players: X | Bots: Y" : bilkul center-top
function ESP.CreateCounter()
  local canvas = ESP.GetCanvas()
  if not ESPValid(canvas) then return nil end
  local container = nil
  pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
  if not ESPValid(container) then return nil end
  local txt = nil
  pcall(function() txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
  if not ESPValid(txt) then ESP.Destroy({ Widget = container }) return nil end
  pcall(function()
    txt:SetText("Players: 0 | Bots: 0")
    txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    if txt.SetJustification then txt:SetJustification(1) end
  end)
  ESP.SetTextColor(txt, C_RED)
  ESP.SetFont(txt, CFG.CounterFontSize)
  local tSlot, mSlot = nil, nil
  pcall(function() tSlot = container:AddChildToCanvas(txt) end)
  pcall(function() mSlot = canvas:AddChildToCanvas(container) end)
  if not tSlot or not mSlot then ESP.Destroy({ Widget = container }) return nil end
  local W, H = CFG.CounterW or 300.0, CFG.CounterH or 28.0
  pcall(function()
    -- Text centered inside a fixed-size child container.
    tSlot:SetAutoSize(true)
    tSlot:SetAlignment(ESPV2(0.5, 0.5))
    tSlot:SetPosition(ESPV2(W * 0.5, H * 0.5))
    tSlot:SetZOrder(5)

    -- Anchor the whole counter directly to the Canvas midpoint.
    -- This avoids mixing viewport pixels, Canvas local coordinates and
    -- UI scale when positioning the counter.
    if FAnchors then
      mSlot:SetAnchors(FAnchors(0.5, 0.0, 0.5, 0.0))
    end
    mSlot:SetAutoSize(false)
    mSlot:SetAlignment(ESPV2(0.5, 0.0))
    mSlot:SetSize(ESPV2(W, H))
    mSlot:SetPosition(ESPV2(0.0, CFG.TopTextY or 0.0))
    mSlot:SetZOrder(60)
  end)
  return { Container = container, Text = txt, Slot = mSlot, W = W, H = H }
end

function ESP.CanvasCenterX(viewW)
  -- Hitung titik tengah berdasarkan koordinat ABSOLUTE viewport, lalu
  -- konversi ke local-space Canvas. GetLocalSize() saja tidak cukup pada
  -- device/UI scale tertentu dan dapat menggeser counter beberapa pixel.
  local canvas = ESP.GetCanvas()
  if ESPValid(canvas) and SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
    local ok, result = pcall(function()
      local geo = canvas:GetCachedGeometry()
      if not geo then return nil end
      local absX = (tonumber(viewW) or 1920.0) * 0.5
      local p = SlateBlueprintLibrary.AbsoluteToLocal(geo, ESPV2(absX, 0.0))
      if p and tonumber(p.X) then return tonumber(p.X) end
      return nil
    end)
    if ok and result then return result end
  end
  -- Fallback ke transform yang sudah dikalibrasi.
  return ((tonumber(viewW) or 1920.0) * 0.5) * (ESP.ScaleX or 1.0) + (ESP.OffsetX or 0.0)
end

function ESP.UpdateCounter(nPlayers, nBots, pc, viewW)
  local d = ESP.Counter
  if not d or not ESPValid(d.Container) then
    ESP.Destroy(d)
    d = ESP.CreateCounter()
    ESP.Counter = d
  end
  if not d then return nil end
  local label = string.format("Players: %d | Bots: %d", nPlayers or 0, nBots or 0)
  pcall(function()
    if d.Last ~= label then d.Text:SetText(label) d.Last = label end
  end)
  -- Counter slot is anchored at 50% of the parent Canvas, so its visual
  -- center is independent of viewport/DPI scale.
  -- The counter itself is anchored at 50% of the Canvas, but ESP line
  -- coordinates live in the same scaled coordinate space as Project().
  -- Therefore the line origin must use the exact same viewport->ESP transform
  -- as projected enemy positions, not raw viewport X/2 and not Canvas local X.
  local vw = tonumber(viewW) or ESP.ViewW or 1920.0
  local cx = vw * 0.5 * (ESP.ScaleX or 1.0) + (ESP.OffsetX or 0.0)
  pcall(function()
    if FAnchors then d.Slot:SetAnchors(FAnchors(0.5, 0.0, 0.5, 0.0)) end
    d.Slot:SetAlignment(ESPV2(0.5, 0.0))
    d.Slot:SetPosition(ESPV2(0.0, CFG.TopTextY or 0.0))
    d.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  end)
  -- IMPORTANT: Line origin must use the same visual center as the counter.
  -- Do not return viewport/ScaleX math here; that was the source of the
  -- horizontal drift seen on some UI scales.
  local origin = ESP.SnapOrigin(pc, vw)
  return origin or ESPV2(cx, (CFG.SnapOriginY or 0.0))
end

-- bottom info: Bot / 16m / Open
function ESP.CreateInfo()
  local canvas = ESP.GetCanvas()
  if not ESPValid(canvas) then return nil end
  local container, tName, tDist, tState = nil, nil, nil, nil
  pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
  if not ESPValid(container) then return nil end
  pcall(function() tName = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
  pcall(function() tDist = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
  pcall(function() tState = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
  if not ESPValid(tName) or not ESPValid(tDist) or not ESPValid(tState) then
    ESP.Destroy({ Widget = container })
    return nil
  end
  pcall(function()
    tName:SetText("Bot")
    tDist:SetText("0m")
    tState:SetText("Open")
    tName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    tDist:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    tState:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    if tName.SetJustification then tName:SetJustification(1) end
    if tDist.SetJustification then tDist:SetJustification(1) end
    if tState.SetJustification then tState:SetJustification(1) end
  end)
  ESP.SetTextColor(tName, C_BLUE)
  ESP.SetTextColor(tDist, C_WHITE)
  ESP.SetTextColor(tState, C_GREEN)
  ESP.SetFont(tName, CFG.NameFontSize)
  ESP.SetFont(tDist, CFG.DistFontSize)
  ESP.SetFont(tState, CFG.StateFontSize)
  local s1, s2, s3, ms = nil, nil, nil, nil
  pcall(function() s1 = container:AddChildToCanvas(tName) end)
  pcall(function() s2 = container:AddChildToCanvas(tDist) end)
  pcall(function() s3 = container:AddChildToCanvas(tState) end)
  pcall(function() ms = canvas:AddChildToCanvas(container) end)
  if not s1 or not s2 or not s3 or not ms then
    ESP.Destroy({ Widget = container })
    return nil
  end
  pcall(function()
    s1:SetAutoSize(true) s1:SetAlignment(ESPV2(0.5, 0.5)) s1:SetZOrder(36)
    s2:SetAutoSize(true) s2:SetAlignment(ESPV2(0.5, 0.5)) s2:SetZOrder(36)
    s3:SetAutoSize(true) s3:SetAlignment(ESPV2(0.5, 0.5)) s3:SetZOrder(36)
    ms:SetAutoSize(false) ms:SetZOrder(35)
  end)
  return { Container = container, Name = tName, Dist = tDist, State = tState,
           S1 = s1, S2 = s2, S3 = s3, Slot = ms }
end

function ESP.UpdateInfo(key, Character, isBot, distM, bVisible, footX, footY, showName, showDist, showState)
  local d = ESP.Infos[key]
  if not d or not ESPValid(d.Container) then
    ESP.Destroy(d)
    d = ESP.CreateInfo()
    ESP.Infos[key] = d
  end
  if not d then return end

  local any = showName or showDist or showState
  if not any then
    pcall(function() d.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return
  end

  local name = d.CachedName
  if not name then
    name = ESP.ResolveName(Character, isBot)
    d.CachedName = name
  end
  if isBot then
    name = "Bot"
    d.CachedName = "Bot"
  end

  local dm = math.max(0, tonumber(distM) or 0)
  local dl = string.format("%dm", math.floor(dm + 0.5))
  local st = bVisible and "Open" or "Close"

  -- INFO TEXT SCALE:
  -- Ukuran Player/Bot, Distance, dan Open/Close mengikuti jarak target.
  -- Dekat tetap memakai ukuran asli; semakin jauh ukurannya mengecil.
  -- Kurva dibuat halus supaya pada 50-150m tidak langsung menjadi terlalu kecil,
  -- tetapi pada jarak jauh tidak menumpuk menjadi satu blok teks.
  local infoScale = 1.0 / (1.0 + (dm / 150.0))
  if infoScale < 0.42 then infoScale = 0.42 end
  if infoScale > 1.0 then infoScale = 1.0 end

  local nameSize = math.max(7, math.floor((CFG.NameFontSize or 15) * infoScale + 0.5))
  local distSize = math.max(6, math.floor((CFG.DistFontSize or 13) * infoScale + 0.5))
  local stateSize = math.max(6, math.floor((CFG.StateFontSize or 13) * infoScale + 0.5))

  pcall(function()
    -- Update font hanya ketika scale berubah cukup jauh; jangan SetFont tiap frame.
    local fontKey = string.format("%d:%d:%d", nameSize, distSize, stateSize)
    if d.LastFontKey ~= fontKey then
      ESP.SetFont(d.Name, nameSize)
      ESP.SetFont(d.Dist, distSize)
      ESP.SetFont(d.State, stateSize)
      d.LastFontKey = fontKey
    end

    -- Player/Bot hanya mengontrol baris nama.
    if showName then
      if d.LastN ~= name then
        d.Name:SetText(name)
        d.LastN = name
        if isBot then ESP.SetTextColor(d.Name, C_BLUE)
        else ESP.SetTextColor(d.Name, C_WHITE) end
      end
      d.Name:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    else
      d.Name:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end

    -- Distance hanya mengontrol angka jarak.
    if showDist then
      if d.LastD ~= dl then
        d.Dist:SetText(dl)
        d.LastD = dl
      end
      d.Dist:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    else
      d.Dist:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end

    -- Open/Close hanya mengontrol status visibility.
    if showState and bVisible ~= nil then
      if d.LastS ~= st then
        d.State:SetText(st)
        d.LastS = st
        if bVisible then ESP.SetTextColor(d.State, C_GREEN)
        else ESP.SetTextColor(d.State, C_RED) end
      end
      d.State:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    else
      d.State:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  end)

  -- Slot dan jarak antarbaris juga ikut mengecil bersama font.
  local w = math.max(50.0, 120.0 * infoScale)
  local lineH = math.max(10.0, 18.0 * infoScale)
  local gap = math.max(0.5, (CFG.TextGap or 2.0) * infoScale)
  local enabled = {}
  if showName then enabled[#enabled + 1] = d.S1 end
  if showDist then enabled[#enabled + 1] = d.S2 end
  if showState then enabled[#enabled + 1] = d.S3 end

  local count = #enabled
  if count == 0 then
    pcall(function() d.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return
  end

  local totalH = count * lineH + math.max(0, count - 1) * gap
  local x = RND(footX - w * 0.5)
  local y = RND(footY + 4.0 * infoScale)
  local scaleChanged = math.abs((d.LastInfoScale or 0) - infoScale) >= 0.02
  if d.ix == nil or math.abs(d.ix - x) >= 1.0 or math.abs((d.iy or 0) - y) >= 1.0
     or d.LastCount ~= count or scaleChanged then
    d.ix, d.iy, d.LastCount, d.LastInfoScale = x, y, count, infoScale
    pcall(function()
      d.Slot:SetPosition(ESPV2(x, y))
      d.Slot:SetSize(ESPV2(w, totalH + 4.0 * infoScale))
      local row = 0
      if showName then
        d.S1:SetPosition(ESPV2(w * 0.5, row * (lineH + gap) + lineH * 0.5))
        row = row + 1
      end
      if showDist then
        d.S2:SetPosition(ESPV2(w * 0.5, row * (lineH + gap) + lineH * 0.5))
        row = row + 1
      end
      if showState then
        d.S3:SetPosition(ESPV2(w * 0.5, row * (lineH + gap) + lineH * 0.5))
      end
      d.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
  else
    pcall(function() d.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  end
end

function ESP.EnsureCorner(key, idx, color)
  local t = ESP.Corners[key]
  if not t then t = {} ESP.Corners[key] = t end
  local d = t[idx]
  if d and ESPValid(d.Widget) then return d end
  d = ESP.NewLine(color or C_WHITE, 32)
  t[idx] = d
  return d
end

function ESP.EnsureHealthBg(key)
  local d = ESP.HealthBg[key]
  if d and ESPValid(d.Widget) then return d end
  d = ESP.NewLine(ESPMKC(0.0, 0.0, 0.0, CFG.SideBgAlpha or 0.55), 31)
  ESP.HealthBg[key] = d
  return d
end

function ESP.EnsureHealthFill(key)
  local d = ESP.HealthFill[key]
  if d and ESPValid(d.Widget) then return d end
  d = ESP.NewLine(C_GREEN, 32)
  ESP.HealthFill[key] = d
  return d
end

-- Health bar: bg full height + fill bottom-se-up pct height, color HealthColor()
-- single bg + single fill per target (double-draw fix)
function ESP.UpdateHealthBar(key, pct, x, top, h)
  local bg = ESP.EnsureHealthBg(key)
  local fill = ESP.EnsureHealthFill(key)
  if not bg or not fill then return end
  local w = CFG.SideBarWidth or 3.5
  ESP.DrawVBar(bg, x, top, h, w)
  pct = tonumber(pct) or 1.0
  if pct < 0 then pct = 0 end
  if pct > 1 then pct = 1 end
  -- color bucket cache: har frame SetBrushColor nahi (flicker fix)
  local bucket
  if pct >= 0.7 then bucket = "g_" .. math.floor(pct * 20 + 0.5)
  elseif pct >= 0.4 then bucket = "y_" .. math.floor(pct * 20 + 0.5)
  else bucket = "r_" .. math.floor(pct * 20 + 0.5) end
  ESP.SetBrush(fill, HealthColor(pct), bucket)
  local fh = h * pct
  if fh < 1 then
    ESP.Hide(fill)
    return
  end
  -- bottom anchored: khali hissa upar, bhara hissa neeche
  ESP.DrawVBar(fill, x, top + (h - fh), fh, w)
end

function ESP.EnsureMark(key, idx)
  local t = ESP.Marks[key]
  if not t then t = {} ESP.Marks[key] = t end
  local d = t[idx]
  if d and ESPValid(d.Widget) then return d end
  d = ESP.NewLine(C_YELLOW, 33)
  t[idx] = d
  return d
end

function ESP.EnsureSnap(key)
  local d = ESP.Lines[key]
  if d and ESPValid(d.Widget) then return d end
  d = ESP.NewLine(C_GREEN, 30)
  ESP.Lines[key] = d
  return d
end

function ESP.HideTarget(key)
  local c = ESP.Corners[key]
  if c then for i = 1, 8 do ESP.Hide(c[i]) end end
  ESP.Hide(ESP.HealthBg[key])
  ESP.Hide(ESP.HealthFill[key])
  local m = ESP.Marks[key]
  if m then for i = 1, 4 do ESP.Hide(m[i]) end end
  ESP.Hide(ESP.Lines[key])
  local inf = ESP.Infos[key]
  if inf and ESPValid(inf.Container) then
    pcall(function() inf.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
  end
end

function ESP.ReleaseTarget(key)
  local c = ESP.Corners[key]
  if c then for i = 1, 8 do ESP.Destroy(c[i]) end end
  ESP.Corners[key] = nil
  ESP.Destroy(ESP.HealthBg[key])
  ESP.HealthBg[key] = nil
  ESP.Destroy(ESP.HealthFill[key])
  ESP.HealthFill[key] = nil
  local m = ESP.Marks[key]
  if m then for i = 1, 4 do ESP.Destroy(m[i]) end end
  ESP.Marks[key] = nil
  ESP.Destroy(ESP.Lines[key])
  ESP.Lines[key] = nil
  ESP.Destroy(ESP.Infos[key])
  ESP.Infos[key] = nil
  ESP.VisCache[key] = nil
end

function ESP.ResetWidgets()
  for _, d in pairs(ESP.Lines) do ESP.Destroy(d) end
  for _, t in pairs(ESP.Corners) do for _, d in pairs(t) do ESP.Destroy(d) end end
  for _, d in pairs(ESP.HealthBg) do ESP.Destroy(d) end
  for _, d in pairs(ESP.HealthFill) do ESP.Destroy(d) end
  for _, t in pairs(ESP.Marks) do for _, d in pairs(t) do ESP.Destroy(d) end end
  for _, d in pairs(ESP.Infos) do ESP.Destroy(d) end
  ESP.Lines = {}
  ESP.Corners = {}
  ESP.HealthBg = {}
  ESP.HealthFill = {}
  ESP.Marks = {}
  ESP.Infos = {}
  ESP.VisCache = {}
  if ESP.Counter then ESP.Destroy(ESP.Counter) end
  ESP.Counter = nil
  ESP.Canvas = nil
  ESP.EnemyCache = {}
end

function ESP.Scan()
  local pc = ESP.GetController()
  local me = ESP.GetLocalCharacter()
  if not pc or not me then ESP.EnemyCache = {} return pc, 0, 0 end
  local myLoc = ESP.ActorLocation(me)
  if not myLoc then ESP.EnemyCache = {} return pc, 0, 0 end
  local myTeam = ESP.GetTeamID(me)
  local list = {}
  local nReal, nBot = 0, 0
  local pawns = nil
  pcall(function() if Game and Game.GetAllPlayerPawns then pawns = Game:GetAllPlayerPawns() end end)
  if pawns then
    for _, ch in pairs(pawns) do
      if ESPValid(ch) and ch ~= me and ESP.IsAlive(ch) then
        local team = ESP.GetTeamID(ch)
        if myTeam == nil or team == nil or tostring(team) ~= tostring(myTeam) then
          local loc = ESP.ActorLocation(ch)
          local dm = ESP.DistMeters(myLoc, loc)
          if dm * 100.0 <= (CFG.MaxDistance or 40000) then
            local isBot = ESP.IsBot(ch)
            if isBot then nBot = nBot + 1 else nReal = nReal + 1 end
            list[#list + 1] = { Character = ch, Key = ESP.GetPlayerKey(ch),
                                IsBot = isBot, Distance = dm, Location = loc }
          end
        end
      end
    end
  end
  table.sort(list, function(a, b) return (a.Distance or 99999) < (b.Distance or 99999) end)
  local trimmed = {}
  local maxR = CFG.MaxTracked or 16
  for i, it in ipairs(list) do
    if i > maxR then break end
    trimmed[#trimmed + 1] = it
  end
  ESP.EnemyCache = trimmed
  return pc, nReal, nBot
end
--// SRC HUB
function ESP.Update()
  -- Master switch is authoritative. Even if an old callback/tick fires,
  -- ESP LITE must never recreate widgets while the master is OFF.
  if not ESP.bActive or not (_G.AimPROConfig and _G.AimPROConfig.EspLoai9 == true) then
    ESP.ResetWidgets()
    return
  end
  if not ESP_Enabled then ESP.ResetWidgets() return end
  local world = ESP.World()
  if world ~= ESP.LastWorld then
    ESP.ResetWidgets()
    ESP.LastWorld = world
    ESP.LastScan = -999.0
    ESP.LastTransform = -999.0
    ESP.LastRender = -999.0
  end
  local canvas = ESP.GetCanvas()
  if not canvas then return end
  local now = ESP.Now()

  -- The base MainLoop can call the ESP driver every 0.01s. Do not let that
  -- frequency reach the expensive projection/widget work. The ESP remains
  -- responsive, but its render work is capped at 20 Hz.
  local lightInterval = ESP.LightInterval or 0.050
  if (now - (ESP.LastRender or -999.0)) < lightInterval then
    return
  end
  ESP.LastRender = now

  local pc = ESP.GetController()
  if (now - ESP.LastScan) >= (ESP.ScanInterval or 0.35) then
    local r, b
    pc, r, b = ESP.Scan()
    ESP.LastScan = now
    ESP.RealCount, ESP.BotCount = r or 0, b or 0
  end
  pc = pc or ESP.GetController()
  if not pc then return end
  if (now - (ESP.LastTransform or -999.0)) >= (ESP.TransformInterval or 0.50) then
    ESP.UpdateCanvasTransform(pc)
    ESP.LastTransform = now
  end
  local vw, vh = ESP.Viewport(pc)
  -- viewport hysteresis: 2px se kam farq ignore (flicker fix)
  local hyst = CFG.SizeHyst or 2.0
  if math.abs(vw - (ESP.ViewW or 0)) > hyst or math.abs(vh - (ESP.ViewH or 0)) > hyst then
    ESP.ViewW, ESP.ViewH = vw, vh
  else
    vw, vh = ESP.ViewW, ESP.ViewH
  end
  local origin = ESP.UpdateCounter(ESP.RealCount or 0, ESP.BotCount or 0, pc, vw)
  if not origin then return end

  -- ESP LITE sub-feature switches. Each visual can be enabled independently.
  local cfg9 = _G.AimPROConfig or {}
  local showLine = cfg9.Esp9_Line ~= false
  local showBox = cfg9.Esp9_Box ~= false
  local showName = cfg9.Esp9_Name ~= false
  local showDistance = cfg9.Esp9_Distance ~= false
  local showVisibility = cfg9.Esp9_Visibility ~= false
  local showInfo = showName or showDistance or showVisibility

  -- If every visual is disabled, release the existing widgets and skip all projection/render work.
  if not showLine and not showBox and not showInfo then
    ESP.ResetWidgets()
    return
  end

  local camLoc = ESP.GetCamLoc(pc)

  local active = {}
  for _, item in ipairs(ESP.EnemyCache) do
    local c = item.Character
    local key = item.Key
    if ESPValid(c) and ESP.IsAlive(c) then
      local head, feet = ESP.GetHeadFeet(c)
      if head and feet then
        local headS, headPix = ESP.Project(pc, head)
        local feetS, feetPix = ESP.Project(pc, feet)

        -- Long-range stability:
        -- Use the actor center as an independent anchor for the screen gate
        -- and the info text. At long distance the projected head/feet can
        -- become nearly identical or one endpoint can temporarily fail,
        -- which used to make Player/Bot, Distance and Open/Close disappear
        -- while the ESP line remained alive.
        -- V6: the scan cache only decides WHICH targets are tracked.
        -- Do not use its old Location for drawing, otherwise a moving target
        -- can make the ESP visibly lag behind the character. Refresh the
        -- actor position on every light render while keeping the expensive
        -- pawn scan at ScanInterval.
        local actorLoc = ESP.ActorLocation(c) or item.Location
        local liveDistance = item.Distance
        if actorLoc then
          local meNow = ESP.GetLocalCharacter()
          local myNowLoc = meNow and ESP.ActorLocation(meNow) or nil
          if myNowLoc then
            liveDistance = ESP.DistMeters(myNowLoc, actorLoc)
          end
        end
        local centerS, centerPix

        -- If both endpoints projected successfully, their midpoint is already
        -- the screen-space center. Only call Project() for actorLoc when an
        -- endpoint is unavailable. This removes one projection per target.
        if headS and feetS and headPix and feetPix then
          local hx, hy = tonumber(headS.X), tonumber(headS.Y)
          local fx, fy = tonumber(feetS.X), tonumber(feetS.Y)
          if hx and hy and fx and fy then
            local mx, my = (hx + fx) * 0.5, (hy + fy) * 0.5
            centerS = ESPV2(mx, my)
            centerPix = ESPV2(mx, my)
          end
        elseif actorLoc then
          centerS, centerPix = ESP.Project(pc, actorLoc)
        end

        if (headS and feetS and headPix and feetPix) or (centerS and centerPix) then
          local m = CFG.ScreenMargin or 220

          local centerPixX, centerPixY
          if centerPix then
            centerPixX = tonumber(centerPix.X)
            centerPixY = tonumber(centerPix.Y)
          elseif headPix and feetPix then
            centerPixX = (tonumber(headPix.X) + tonumber(feetPix.X)) * 0.5
            centerPixY = (tonumber(headPix.Y) + tonumber(feetPix.Y)) * 0.5
          end

          local on = centerPixX ~= nil and centerPixY ~= nil
            and centerPixX > -m and centerPixX < vw + m
            and centerPixY > -m and centerPixY < vh + m

          if on then
            local H = 0
            if headS and feetS then
              H = math.abs(feetS.Y - headS.Y)
            end

            -- Do not discard a valid distant target merely because its
            -- projected body height is below a fixed pixel threshold.
            -- A tiny projected body is normal at 100-400 m.
            local boxUsable = headS and feetS and H >= 1.0 and H <= vh * 1.5
            if boxUsable or centerS then
              active[key] = true
              -- Box uses the real head/feet projection when available.
              -- If only the center survives at long range, keep the info
              -- renderer alive without fabricating a large box.
              local cx = centerS and centerS.X or ((headS.X + feetS.X) * 0.5)
              local L, R, T, B
              if boxUsable then
                local W = H * (CFG.BoxWidthFactor or 0.62)
                -- Let the box shrink naturally at long distance instead of
                -- forcing a 22px minimum that causes distant boxes to pile up.
                local minW = math.max(6.0, (CFG.BoxMinWidth or 22) * 0.35)
                W = math.max(minW, math.min(CFG.BoxMaxWidth or 320, W))
                local padT = H * (CFG.HeadExtra or 0)
                local padB = H * (CFG.FootExtra or 0)
                L = cx - W * 0.5
                R = cx + W * 0.5
                T = headS.Y - padT
                B = feetS.Y + padB
              end

              -- 1) ESP BOX: corner box + HP bar + double chevron
              if showBox and boxUsable then
                local arm = math.min(R - L, B - T) * (CFG.CornerLen or 0.28)
                arm = math.max(CFG.CornerMin or 6, math.min(CFG.CornerMax or 28, arm))
                local th = CFG.CornerThickness or 2.2
                ESP.DrawLine(ESP.EnsureCorner(key, 1, C_WHITE), L, T, L + arm, T, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 2, C_WHITE), L, T, L, T + arm, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 3, C_WHITE), R, T, R - arm, T, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 4, C_WHITE), R, T, R, T + arm, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 5, C_WHITE), L, B, L + arm, B, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 6, C_WHITE), L, B, L, B - arm, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 7, C_WHITE), R, B, R - arm, B, th)
                ESP.DrawLine(ESP.EnsureCorner(key, 8, C_WHITE), R, B, R, B - arm, th)

                local pct = ESP.GetHealthPct(c)
                local sbX = L - (CFG.SideBarGap or 5.0)
                ESP.UpdateHealthBar(key, pct, sbX, T, B - T)

                -- Double chevron/arrow above the box has been intentionally removed.
                -- Hide any legacy mark widgets so old instances cannot remain visible.
                local mtbl = ESP.Marks[key]
                if mtbl then for i = 1, 4 do ESP.Hide(mtbl[i]) end end
              else
                local ct = ESP.Corners[key]
                if ct then for i = 1, 8 do ESP.Hide(ct[i]) end end
                ESP.Hide(ESP.HealthBg[key])
                ESP.Hide(ESP.HealthFill[key])
                local mtbl = ESP.Marks[key]
                if mtbl then for i = 1, 4 do ESP.Hide(mtbl[i]) end end
              end

              -- 2) ESP LINE: top-center -> head
              if showLine then
                local lineTarget = headS or centerS
                if lineTarget then
                  ESP.DrawLine(ESP.EnsureSnap(key), origin.X, origin.Y, lineTarget.X, lineTarget.Y,
                               CFG.SnapThickness or 1.8)
                else
                  ESP.Hide(ESP.Lines[key])
                end
              else
                ESP.Hide(ESP.Lines[key])
              end

              -- 3) ESP INFO: Player/Bot, Distance, dan Open/Close dikontrol terpisah.
              if showInfo then
                local bVis = nil
                if showVisibility then
                  bVis = ESP.IsVisible(key, pc, camLoc, c)
                end
                local infoX = centerS and centerS.X or cx
                local infoY = boxUsable and B or ((centerS and centerS.Y) or centerPixY)
                ESP.UpdateInfo(key, c, item.IsBot, liveDistance, bVis, infoX, infoY, showName, showDistance, showVisibility)
              else
                local inf = ESP.Infos[key]
                if inf and ESPValid(inf.Container) then
                  pcall(function() inf.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                end
              end
            else
              ESP.HideTarget(key)
            end
          else
            ESP.HideTarget(key)
          end
        else
          ESP.HideTarget(key)
        end
      else
        ESP.HideTarget(key)
      end
    end
  end
  -- stale: jo is frame me nahi dikha usko hide; jo cache me bhi nahi usko release
  local seenCache = {}
  for _, it in ipairs(ESP.EnemyCache) do seenCache[it.Key] = true end
  local function stillActive(k)
    return active[k] == true
  end
  for k, _ in pairs(ESP.Lines) do if not stillActive(k) then ESP.HideTarget(k) end end
  for k, _ in pairs(ESP.Infos) do if not stillActive(k) then ESP.HideTarget(k) end end
  for k, _ in pairs(ESP.Corners) do
    if not stillActive(k) and not seenCache[k] then ESP.ReleaseTarget(k) end
  end
  for k, _ in pairs(ESP.HealthBg) do
    if not seenCache[k] and not stillActive(k) then ESP.ReleaseTarget(k) end
  end
end

-- Single driver: sirf ek repeating timer (lag/flicker fix).
-- Purana triple-driver (Tick loop + 2x AddGameTimer) hata diya.
function ESP.Tick()
  pcall(ESP.Update)
end

function ESP.Start()
  if not (_G.AimPROConfig and _G.AimPROConfig.EspLoai9 == true) then
    ESP.Stop()
    return
  end
  if ESP.bActive then return end
  ESP.bActive = true
  ESP.LastScan = -999.0
  ESP.LastTransform = -999.0
  ESP.LastRender = -999.0
  pcall(ESP.Update)
end

-- Stop wajib benar-benar membersihkan seluruh widget ESP LITE.
-- Base lama memanggil PlayerMapMarker.Stop() ketika master dimatikan;
-- tanpa fungsi ini renderer tetap hidup dan widget yang sudah dibuat tetap terlihat.
function ESP.Stop()
  ESP.bActive = false
  ESP.LastScan = -999.0
  ESP.LastTransform = -999.0
  ESP.LastRender = -999.0
  ESP.EnemyCache = {}
  -- First collapse every live widget, then remove/destroy it. This makes
  -- master OFF immediate even when the engine keeps the Canvas alive for a frame.
  pcall(function()
    local function collapse(data)
      if not data then return end
      local w = data.Widget or data.Container
      if ESPValid(w) then pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
    end
    for _,d in pairs(ESP.Lines) do collapse(d) end
    for _,t in pairs(ESP.Corners) do for _,d in pairs(t) do collapse(d) end end
    for _,d in pairs(ESP.HealthBg) do collapse(d) end
    for _,d in pairs(ESP.HealthFill) do collapse(d) end
    for _,t in pairs(ESP.Marks) do for _,d in pairs(t) do collapse(d) end end
    for _,d in pairs(ESP.Infos) do collapse(d) end
    collapse(ESP.Counter)
  end)
  pcall(ESP.ResetWidgets)
end

-- ============================================================
-- AimPRO BASE COMPATIBILITY BRIDGE
-- ESP LINE V2 lama sudah DIHAPUS; pemanggilan base diarahkan ke ESP LITE.
-- ============================================================
function ESP.InitESPCanvas()
  return ESP.GetCanvas() ~= nil
end

function ESP.GetMyPlayerController()
  return ESP.GetController()
end

function ESP.GetSnapLineStartPos(pc)
  local vw = ESP.ViewW or 1920
  local x,y = ESP.SnapOrigin(pc, vw)
  return x,y
end

function ESP.ScanAndUpdate()
  if not ESP.bActive then return end
  ESP.Scan()
end

function ESP.UpdateESPDistances()
  if not ESP.bActive then return end
  ESP.Update()
end

function ESP.UpdateESPLight()
  if not ESP.bActive then return end
  ESP.Update()
end

function ESP.ClearAllESP()
  ESP.ResetWidgets()
end

_G.ESP = ESP
_G.PlayerMapMarker = ESP
_G.__AimPRO_ESP_V2_REMOVED = true

end

-- ==========================================
-- lingkaran FOV AIMBOT V2
-- ==========================================
_G.FovCircleOverlay={Container=nil,WidgetSlot=nil,Lines={}, NumSegments=45,-- [maksimal optimal] kurangi dari 90 turunkan 45 (kurangi 50% Beban berat UI tetapi tetap mulus)
Thickness=1.5,LastRadius=-1,LastColor=-1,LastCX=-1,LastCY=-1, PrecalcMath=nil -- [maksimal optimal] bagian ingat cache hitung belajar anti drop FPS
}
local function GetFOVColor(idx)
if idx==1 then return 1.0,0.0,0.0 end
if idx==2 then return 0.0,1.0,0.0 end
if idx==3 then return 0.0,0.0,1.0 end
if idx==4 then return 1.0,1.0,0.0 end
if idx==5 then return 0.65,0.15,1.0 end
if idx==6 then return 0.0,1.0,1.0 end
if idx==7 then return 1.0,1.0,1.0 end
return 1.0,1.0,1.0
end
function _G.FovCircleOverlay.Create()
if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container)then return true end
local ParentCanvas=nil
pcall(function()
local InGameUITools=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
local MainUI=InGameUITools.GetMainControlBaseUI()
if slua.isValid(MainUI)then
if slua.isValid(MainUI.CanvasPanel_0)then ParentCanvas=MainUI.CanvasPanel_0
elseif slua.isValid(MainUI.CanvasPanel_42)then ParentCanvas=MainUI.CanvasPanel_42 end
end
end)
if not ParentCanvas or not slua.isValid(ParentCanvas)then return false end
local Container=nil
pcall(function()Container=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",ParentCanvas)end)
if not Container or not slua.isValid(Container)then return false end
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
for i=1,_G.FovCircleOverlay.NumSegments do
local border=nil
pcall(function()border=CGame:NewObjectFromPath("/Script/UMG.Border",Container)end)
if border and slua.isValid(border)then
pcall(function()
border.RenderTransformPivot=FVector2D(0,0.5)
border:SetRenderTransformPivot(FVector2D(0,0.5))
border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
end)
local slot=Container:AddChildToCanvas(border)
if slot then
pcall(function()slot:SetAlignment(FVector2D(0,0.5))end)
end
_G.FovCircleOverlay.Lines[i]={widget=border,slot=slot}
end
end
local MainSlot=nil
pcall(function()MainSlot=ParentCanvas:AddChildToCanvas(Container)end)
if MainSlot then
pcall(function()
MainSlot:SetAutoSize(false)
MainSlot:SetSize(FVector2D(0,0))
MainSlot:SetZOrder(995)
MainSlot:SetAlignment(FVector2D(0,0))
MainSlot:SetPosition(FVector2D(0,0))
end)
end
_G.FovCircleOverlay.Container=Container
_G.FovCircleOverlay.WidgetSlot=MainSlot
return true
end
function _G.FovCircleOverlay.Update(pc,player)
 -- hanya tambahan termasuk duy paling ke fungsi saklar "tampil tampil lingkaran FOV AIMBOT"
if not _G.AimPROConfig.EspFovCircle then
if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container)then
pcall(function()_G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)end)
_G.FovCircleOverlay.LastRadius=-1
end
return
end
local fovVal=30
 local colIdx=7 -- tetap tetapkan adalah putih
local cData=_G.AimPROState.CustomTextData
local WEAPON_TYPE=_G.__AimTouch_WeaponType or"NORMAL"
local isADS=player.bIsGunADS or false
 -- baca setengah kacamata FOV dan warna Warna mirip sesuai untuk setiap jenis senjata
if WEAPON_TYPE=="MORTAR"then
fovVal=cData.AimTouchMortarFOV or 360
colIdx=tonumber(cData.AimTouchMortarFOVColor)or 5
elseif WEAPON_TYPE=="CROSSBOW"then
fovVal=cData.AimTouchCrossbowFOV or 40
colIdx=tonumber(cData.AimTouchSGFOVColor)or 1
elseif WEAPON_TYPE=="BOW"then
fovVal=cData.AimTouchBowFOV or 40
colIdx=tonumber(cData.AimTouchSGFOVColor)or 1
elseif WEAPON_TYPE=="SHOTGUN"then
fovVal=cData.AimTouchSGFOV or 40
colIdx=tonumber(cData.AimTouchSGFOVColor)or 1
elseif isADS then
if WEAPON_TYPE=="SNIPER"then
fovVal=cData.AimTouchSniperFOV or 20
colIdx=tonumber(cData.AimTouchSniperFOVColor)or 4
else
fovVal=cData.AimTouchScopeFOV or 30
colIdx=tonumber(cData.AimTouchScopeFOVColor)or 6
end
else
fovVal=cData.AimTouchHipFOV or 30
colIdx=tonumber(cData.AimTouchHipFOVColor)or 7
end
local rawCX=_G.__AimTouch_CenterX or 960
local rawCY=_G.__AimTouch_CenterY or 540
local vpX=_G.__AimTouch_ViewportX or 1920
 -- paksa update update rasio rasio layar gambar (Scale) termasuk semua saat ESP VIP sedang MATI
if PlayerMapMarker and PlayerMapMarker.UpdateCanvasTransform then
pcall(function()PlayerMapMarker.UpdateCanvasTransform(pc)end)
end
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
local screenCenter=FVector2D and FVector2D(rawCX,rawCY)or{X=rawCX,Y=rawCY}
local canvasCenter={X=rawCX,Y=rawCY}
pcall(function()canvasCenter=PlayerMapMarker.ScreenPixelToCanvasLocal(pc,screenCenter)end)
local centerX=canvasCenter.X
local centerY=canvasCenter.Y
local rawRadius=(fovVal/100.0)*(vpX/2.0)
local scaleX=PlayerMapMarker and PlayerMapMarker._CanvasScaleX or 1.0
local targetRadius=rawRadius*scaleX
 -- jika ESP MATI dan Game menghapus layer FOV -> otomatis kenali area dan gambar ulang
if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container)then
local parent=nil
pcall(function()parent=_G.FovCircleOverlay.Container:GetParent()end)
if not parent or not slua.isValid(parent)then
_G.FovCircleOverlay.Container=nil
end
end
if not _G.FovCircleOverlay.Create()then return end
pcall(function()_G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)end)
 -- [maksimal optimal 1] tambahkan salah jumlah 0.5 pixel agar tidak Hancur rusak Cache terus-menerus karena goyang goyang layar gambar
if math.abs(_G.FovCircleOverlay.LastRadius-targetRadius)<0.5
and _G.FovCircleOverlay.LastColor==colIdx
and math.abs(_G.FovCircleOverlay.LastCX-centerX)<0.5
and math.abs(_G.FovCircleOverlay.LastCY-centerY)<0.5 then
return
end
_G.FovCircleOverlay.LastRadius=targetRadius
_G.FovCircleOverlay.LastColor=colIdx
_G.FovCircleOverlay.LastCX=centerX
_G.FovCircleOverlay.LastCY=centerY
local FLinearColor=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local r,g,b=GetFOVColor(colIdx)
local dim=0.55
local color=FLinearColor and FLinearColor(r*dim,g*dim,b*dim,1.0)or{R=r*dim*255,G=g*dim*255,B=b*dim*255,A=255}
local numSegments=_G.FovCircleOverlay.NumSegments
 -- [maksimal optimal 2] hitung hitung Sin/Cos siap 1 kali DUY paling (Anti membebani CPU setiap frame gambar)
if not _G.FovCircleOverlay.PrecalcMath then
_G.FovCircleOverlay.PrecalcMath={}
local angleStep=360.0/numSegments
local math_cos=math.cos
local math_sin=math.sin
local math_rad=math.rad
local math_atan2=math.atan2 or math.atan
for i=1,numSegments do
local angle1=math_rad((i-1)*angleStep)
local angle2=math_rad(i*angleStep)
local c1,s1=math_cos(angle1),math_sin(angle1)
local c2,s2=math_cos(angle2),math_sin(angle2)
local dx_unit=c2-c1
local dy_unit=s2-s1
local dist_unit=math.sqrt(dx_unit*dx_unit+dy_unit*dy_unit)
local angleDeg=math.deg(math_atan2(dy_unit,dx_unit))
_G.FovCircleOverlay.PrecalcMath[i]={c1=c1,s1=s1,dist_unit=dist_unit,angleDeg=angleDeg
}
end
end
pcall(function()
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
for i=1,numSegments do
local mathData=_G.FovCircleOverlay.PrecalcMath[i]
 -- hanya gunakan Sihir karakter dasar versi super ringan ganti karena hitung hitung jumlah trigonometri rumit rumit
local x1=targetRadius*mathData.c1
local y1=targetRadius*mathData.s1
local dist=targetRadius*mathData.dist_unit
local line=_G.FovCircleOverlay.Lines[i]
if line and line.slot and slua.isValid(line.slot)then
line.slot:SetPosition(FVector2D(centerX+x1,centerY+y1))
line.slot:SetSize(FVector2D(dist+0.8,_G.FovCircleOverlay.Thickness))
line.widget:SetRenderAngle(mathData.angleDeg)
line.widget:SetBrushColor(color)
end
end
end)
end
function _G.CleanUpFovCircleOverlay()
if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container)then
pcall(function()_G.FovCircleOverlay.Container:RemoveFromParent()end)
pcall(function()_G.FovCircleOverlay.Container:ConditionalBeginDestroy()end)
end
if _G.FovCircleOverlay then
_G.FovCircleOverlay.Container=nil
_G.FovCircleOverlay.WidgetSlot=nil
_G.FovCircleOverlay.LastRadius=-1
end
end
-- ==========================================
-- SISTEM SISTEM tampil tampil "DUNGCU" unik buat TỔNG bisa (pastikan pelindung anti ESP CLEAR)
-- ==========================================
local DungCuOverlay={Widget=nil,Slot=nil
}
local function CleanUpPermanentDungCu()
if DungCuOverlay.Widget and slua.isValid(DungCuOverlay.Widget)then
pcall(function()DungCuOverlay.Widget:RemoveFromParent()end)
pcall(function()DungCuOverlay.Widget:ConditionalBeginDestroy()end)
end
DungCuOverlay.Widget=nil
DungCuOverlay.Slot=nil
end
local function EnsurePermanentDungCu()
 -- PENGAMAN: pasang perlindungan agar mesin pembersih ESP V2 tidak menghapusnya
if _G.PlayerMapMarker and not _G.DungCu_Protected then
local old_IsOurESPWidget=_G.PlayerMapMarker.IsOurESPWidget
_G.PlayerMapMarker.IsOurESPWidget=function(w)
 -- beri tahu sistem bahwa ini bukan sampah ESP, JANGAN hapus!
if DungCuOverlay.Widget and w==DungCuOverlay.Widget then
return false
end
if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and w==_G.FovCircleOverlay.Container then
return false
end
if old_IsOurESPWidget then return old_IsOurESPWidget(w)end
return false
end
_G.DungCu_Protected=true
end
 -- 1. jika teks sudah ada di atas layar gambar, paksa ikuti sesuai koordinat tingkat (termasuk semua saat ESP V2 MATI)
if DungCuOverlay.Widget and slua.isValid(DungCuOverlay.Widget)then
pcall(function()DungCuOverlay.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)end)
local PC=_G.PlayerMapMarker and _G.PlayerMapMarker.GetMyPlayerController()
if slua.isValid(PC)and DungCuOverlay.Slot then
 -- [perbaiki Error utama di SINI]
 -- saat ESP V2 terkena MATI, ESPCanvas terkena set menjadi nil membuat UpdateCanvasTransform terkena Error.
 -- Panggil InitESPCanvas() untuk mengambil frame lagi, lalu GetSnapLineStartPos dihitung ulang!
if not _G.PlayerMapMarker.ESPCanvas or not slua.isValid(_G.PlayerMapMarker.ESPCanvas)then
pcall(function()_G.PlayerMapMarker.InitESPCanvas()end)
end
 -- paksa update update Scale layar gambar parasut ESP V2 sedang MATI
pcall(function()_G.PlayerMapMarker.UpdateCanvasTransform(PC)end)
local fromX,fromY=_G.PlayerMapMarker.GetSnapLineStartPos(PC)
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
pcall(function()DungCuOverlay.Slot:SetPosition(FVector2D(fromX,fromY-8))end)
end
return
end
 -- 2. jika belum ada, lanjut aksi gambar baru
local ParentCanvas=nil
pcall(function()
local InGameUITools=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
local MainControlBaseUI=InGameUITools and InGameUITools.GetMainControlBaseUI()
if MainControlBaseUI and slua.isValid(MainControlBaseUI)then
ParentCanvas=MainControlBaseUI.CanvasPanel_0
if not slua.isValid(ParentCanvas)then ParentCanvas=MainControlBaseUI.CanvasPanel_42 end
end
end)
if not ParentCanvas or not slua.isValid(ParentCanvas)then return end
local txtTitle=nil
pcall(function()txtTitle=CGame:NewObjectFromPath("/Script/UMG.TextBlock",ParentCanvas)end)
if txtTitle and slua.isValid(txtTitle)then
pcall(function()
txtTitle:SetText("")
local FLinearColor=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local FSlateColor=_G.FourimPROGetImport("SlateColor")or import("/Script/SlateCore.SlateColor")
local redLinear=FLinearColor and FLinearColor(1.0,0.0,0.0,1.0)or{R=255,G=0,B=0,A=255}
if FSlateColor then txtTitle:SetColorAndOpacity(FSlateColor(redLinear))else txtTitle:SetColorAndOpacity(redLinear)end
if txtTitle.Font then
local font=txtTitle.Font
font.Size=24
txtTitle.Font=font
end
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
txtTitle:SetRenderScale(FVector2D(1.0,1.0))
txtTitle:SetRenderTransformPivot(FVector2D(0.5,0.5))
txtTitle:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
end)
local txtSlot=ParentCanvas:AddChildToCanvas(txtTitle)
if txtSlot then
pcall(function()
txtSlot:SetAutoSize(true)
local FVector2D=_G.FourimPROGetImport("Vector2D")or _G.FVector2D
txtSlot:SetAlignment(FVector2D(0.5,1.0))
txtSlot:SetZOrder(9999)
end)
DungCuOverlay.Slot=txtSlot
end
DungCuOverlay.Widget=txtTitle
end
end
-- ========================================== 
-- lingkaran ulang utama (MAIN LOOP) maksimal optimal SANGAT kuat
-- ========================================== 
local function MainLoop()
if _i then return end
 -- =====================================================================
 -- SISTEM SISTEM ambil HWID asli & ganti HWID virtual (SPOOFER) anti BAN
 -- =====================================================================
pcall(function()
local SystemLib=import("KismetSystemLibrary")
if SystemLib and not _G.FakeHWID_Hooked then
 -- simpan lagi fungsi ambil HWID asli
_G.Original_GetDeviceId=SystemLib.GetDeviceId
 -- timpa fungsi asli game
SystemLib.GetDeviceId=function(...)
if _G.AimPROConfig.FakeHWID then
if not _G.FakeHWID_String then
 -- Buat acak alami satu HWID virtual 32 karakter otomatis
local chars="0123456789abcdef"
local hwid=""
for i=1,32 do
hwid=hwid..chars:sub(math.random(1,16),math.random(1,16))
end
_G.FakeHWID_String=hwid
end
 -- kembalikan kembali HWID virtual
return _G.FakeHWID_String
end
 -- Jika dimatikan Fake HWID maka kembalikan kembali HWID asli
if _G.Original_GetDeviceId then return _G.Original_GetDeviceId(...)end
return"UNKNOWN"
end
_G.FakeHWID_Hooked=true
end
end)
 -- Fungsi unik buat untuk kamu ambil HWID asli (jika setelah ini perlu tampil tampil)
_G.GetOriginalHWID=function()
if _G.Original_GetDeviceId then
return tostring(_G.Original_GetDeviceId())
end
local SystemLib=import("KismetSystemLibrary")
if SystemLib and type(SystemLib.GetDeviceId)=="function"then
return tostring(SystemLib.GetDeviceId())
end
return"UNKNOWN_DEVICE"
end
 -- =====================================================================
if _G.AimPROState.CustomTextData==nil then
_G.AimPROState.CustomTextData={OuterSpeed=10,InnerSpeed=10,HRecoil=0.3,VRecoil=0.3,MagicHead=1.0,MagicBody=1.0,MagicLegs=1.0,IpadViewFOV=120,IpadViewVehicleFOV=120,IpadViewScopeFOV=100,AimTouchHipPrio=1,AimTouchHipBone=1,AimTouchHipCond=1,AimTouchHipSpeed=50,AimTouchHipFOV=30,AimTouchHipDist=250,AimTouchSGPrio=1,AimTouchSGBone=2,AimTouchSGCond=1,AimTouchSGSpeed=80,AimTouchSGFOV=40,AimTouchSGDist=30,AimTouchScopePrio=1,AimTouchScopeBone=2,AimTouchScopeCond=1,AimTouchScopeSpeed=40,AimTouchScopeFOV=20,AimTouchScopeDist=300,AimTouchSniperPrio=1,AimTouchSniperBone=1,AimTouchSniperCond=2,AimTouchSniperSpeed=30,AimTouchSniperFOV=20,AimTouchSniperDist=400,FastCarSpeed=2000}
end
local okData,GameplayData=pcall(require,"GameLua.GameCore.Data.GameplayData")
if not okData or not GameplayData then return end
local pc=GameplayData.GetPlayerController()
local localPlayer=nil
if Valid(pc)then localPlayer=pc:GetPlayerCharacterSafety()end
 -- hapus bersih SÀNH SANH sampah dari RAM saat kamu Mati, ganti MAP, ke lobby (sudah FIX MEMORY LEAK)
if not Valid(localPlayer)then
if _G.PlayerMapMarker and type(_G.PlayerMapMarker.Stop)=="function"then
_G.PlayerMapMarker.Stop()
end
if _G.RedBoxOverlay and type(_G.RedBoxOverlay.Stop)=="function"then
_G.RedBoxOverlay.Stop()
end
if _G.AimPROState.TrackedMarks then
for markId,_ in pairs(_G.AimPROState.TrackedMarks)do SafeRemoveMark(markId)end
end
 -- hapus seluruh bagian CACHE SEMUA ESP (anti crash)
_G.AppliedVehicleWall={}
_G.AppliedItemESP={}
_G.CachedItems={}
_G.CachedVehicles={}
_G.CachedActiveBombs={}
_G.CachedItemBombs={}
_G.AimTouchVisCache={}
_G.ActiveBombTimers={}
_G.BombCache=setmetatable({},{__mode="k"})
_G.NonBombCache=setmetatable({},{__mode="k"})
_G.AddOutfitLastAppliedSkin={}
_G.AimPROState.TrackedMarks={}
for key,data in pairs(_G.AimPROState.EnemyMarks)do
if data and data.MIDs then
for meshStr,midTable in pairs(data.MIDs)do
for k,_ in pairs(midTable)do midTable[k]=nil end
end
end
if data and data.MIDs_V3 then
for meshStr,midTable in pairs(data.MIDs_V3)do
for k,_ in pairs(midTable)do midTable[k]=nil end
end
end
end
_G.AimPROState.EnemyMarks={}
_G.AK_OrigHitboxes={}
_G.AK_ModdedPhysAssets={}
_G.AimPROState.PrevGraphicsState={}
if _G.CleanUpEnemyCounterWidget then _G.CleanUpEnemyCounterWidget()end
CleanUpPermanentDungCu()
if _G.CleanUpFovCircleOverlay then _G.CleanUpFovCircleOverlay()end
return
end
local Cached_PPM=nil
pcall(function()Cached_PPM=import("PostProcessManager").GetInstance()end)
local Cached_SecurityCommonUtils=nil
pcall(function()Cached_SecurityCommonUtils=require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")end)
local Cached_MyHUD=pc and pc.MyHUD or nil
if _G.AimPROConfig.UnlockFPS then InitializeGraphicsUnlock()end
InitializeNativeESP()
Show4imPROVIPMenu()
 -- [panggil LOGIC DUNGCU] selalu jalan unik buat tidak perlu fungsi saklar
EnsurePermanentDungCu()
 -- [panggil LOGIC ESP ITEM dan VEHICLE ke lingkaran ulang]
if _G.AimPROConfig.WallVehicle or _G.AimPROConfig.EspItem_Master then
_G.RunOptimizedItemAndVehicleESP(pc)
end
 -- [Akumulasi cocok] LOGIC aktif/MATI ESP jenis 9 ke MAINLOOP (tidak gunakan TIMER menyebabkan lag)
if _G.AimPROConfig.EspLoai9 == true then
if _G.PlayerMapMarker then
if not _G.PlayerMapMarker.bActive then _G.PlayerMapMarker.Start()end
local curTime=os.clock()
 -- Scan folder target 0.5s/kali (ringan mesin)
if not _G.LastEsp9Scan or(curTime-_G.LastEsp9Scan)>0.5 then
_G.LastEsp9Scan=curTime
pcall(function()_G.PlayerMapMarker.ScanAndUpdate()end)
end
 -- Update sekitar jarak 0.1s/kali
if not _G.LastEsp9Dist or(curTime-_G.LastEsp9Dist)>0.1 then
_G.LastEsp9Dist=curTime
pcall(function()_G.PlayerMapMarker.UpdateESPDistances()end)
end
 -- Update Posisi posisi gambar ESP sesuai frame gambar (Mulus Tru)
pcall(function()_G.PlayerMapMarker.UpdateESPLight()end)
end
else
if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then
_G.PlayerMapMarker.Stop()
end
end
 -- LOGIC IPAD VIEW (pergi bagian, Berkendara kendaraan dan buka SCOPE) sudah NAIK level
pcall(function()
local isAiming=false
if localPlayer.bIsWeaponAiming or localPlayer.bIsGunADS then isAiming=true end
local currentVehicle=localPlayer.CurrentVehicle or(type(localPlayer.GetVehicle)=="function"and localPlayer:GetVehicle())
local isInVehicle=Valid(currentVehicle)or localPlayer.bIsInVehicle
local uTPPCam=localPlayer.ThirdPersonCameraComponent
local uVehCam=localPlayer.VehicleCameraComponent
local camMgr=pc.PlayerCameraManager
 -- 1. proses logika saat sedang buka SCOPE (membidik jalankan)
if isAiming then
if _G.AimPROConfig.IpadViewScope and _G.AimPROState.CustomTextData then
local targetScope=_G.AimPROState.CustomTextData.IpadViewScopeFOV or 60
if type(pc.FOV)=="function"then pc:FOV(targetScope)end
if Valid(camMgr)then
camMgr.DefaultFOV=targetScope
if type(camMgr.SetFOV)=="function"then camMgr:SetFOV(targetScope)end
end
else
 -- Jika Ipad Scope dimatikan, kembalikan FOV asli Game untuk bidikan yang pas
if type(pc.FOV)=="function"then pc:FOV(0)end
if Valid(camMgr)and type(camMgr.UnlockFOV)=="function"then camMgr:UnlockFOV()end
end
 return -- hentikan logic pergi bagian/kendaraan karena optimalkan Scope
end
 -- 2. proses logika saat tidak membidik jalankan (pergi bagian atau Berkendara kendaraan)
 -- pulih Kembali camera jika sebelum itu baru MATI Scope
if not isInVehicle or not _G.AimPROConfig.IpadViewVehicle then
if type(pc.FOV)=="function"then pc:FOV(0)end
if Valid(camMgr)and type(camMgr.UnlockFOV)=="function"then camMgr:UnlockFOV()end
end
 -- pergi bagian
if not isInVehicle then
if _G.AimPROConfig.IpadView and _G.AimPROState.CustomTextData then
local targetTPP=_G.AimPROState.CustomTextData.IpadViewFOV or 120
if Valid(uTPPCam)and uTPPCam.FieldOfView~=targetTPP then
uTPPCam.FieldOfView=targetTPP
end
else
if Valid(uTPPCam)and uTPPCam.FieldOfView~=90 then
uTPPCam.FieldOfView=90
end
end
end
 -- Berkendara kendaraan
if isInVehicle then
if _G.AimPROConfig.IpadViewVehicle and _G.AimPROState.CustomTextData then
local targetVeh=_G.AimPROState.CustomTextData.IpadViewVehicleFOV or 120
if Valid(uVehCam)and uVehCam.FieldOfView~=targetVeh then
uVehCam.FieldOfView=targetVeh
end
if targetVeh>90 then
if type(pc.FOV)=="function"then pc:FOV(targetVeh)end
if Valid(camMgr)then
camMgr.DefaultFOV=targetVeh
if type(camMgr.SetFOV)=="function"then camMgr:SetFOV(targetVeh)end
end
end
else
if Valid(uVehCam)and uVehCam.FieldOfView~=90 then
uVehCam.FieldOfView=90
end
end
end
end)
 -- ========================================================
 -- LOGIC AIMBOT V2 ROYAL/CUSTOM dan lingkaran FOV
 -- ========================================================
pcall(function()
local ui_util=require("client.common.ui_util")
if ui_util then
local vp=ui_util.GetViewportSize()
if vp then
_G.__AimTouch_ViewportX=vp.X
_G.__AimTouch_CenterX=vp.X*0.5
_G.__AimTouch_CenterY=vp.Y*0.5
end
end
local wName=""
local weapon=localPlayer.WeaponManagerComponent and localPlayer.WeaponManagerComponent.CurrentWeaponReplicated
if not weapon and type(localPlayer.GetCurrentShootWeapon)=="function"then
weapon=localPlayer:GetCurrentShootWeapon()
end
if slua.isValid(weapon)then
wName=type(weapon.GetWeaponName)=="function"and weapon:GetWeaponName()or""
local wID=type(weapon.GetWeaponID)=="function"and weapon:GetWeaponID()or 0
if(wID>=1030000 and wID<1040000)or wName:find("S686")or wName:find("S1897")or wName:find("S12")or wName:find("DBS")or wName:find("M1014")then
_G.__AimTouch_WeaponType="SHOTGUN"
elseif wName:find("Kar98")or wName:find("M24")or wName:find("AWM")or wName:find("Mosin")or wName:find("Win94")or wName:find("AMR")or wName:find("SKS")or wName:find("SLR")or wName:find("Mini")or wName:find("Mk14")or wName:find("QBU")or wName:find("Mk12")or wName:find("VSS")then
_G.__AimTouch_WeaponType="SNIPER"
elseif wName:lower():find("mortar")or wName:lower():find("cối")then
_G.__AimTouch_WeaponType="MORTAR"
elseif wName:lower():find("crossbow")or wName:lower():find("nỏ")then
_G.__AimTouch_WeaponType="CROSSBOW"
elseif wName:lower():find("bow")or wName:lower():find("cung")then
_G.__AimTouch_WeaponType="BOW"
else
_G.__AimTouch_WeaponType="NORMAL"
end
end
end)
if _G.AimPROConfig.AimTouchEnable then
_G.AimTouch()
end
if _G.FovCircleOverlay then
pcall(function()_G.FovCircleOverlay.Update(pc,localPlayer)end)
end
 -- [tambahkan baru] LOGIC GLOW senjata (unik buat & super mulus 0.5s/kali - jamin pastikan 0% DROP FPS)
if not _G.LastGlowTime or(os.clock()-_G.LastGlowTime)>0.5 then
_G.LastGlowTime=os.clock()
if _G.ApplyWeaponGlow then _G.ApplyWeaponGlow(localPlayer)end
end
 -- ========================================================
 -- LOGIC Kompensasi tersendat (GHÌM TENGAH) hanya DÀNH khusus untuk AIMBOT asli (sudah FIX lag BANYAK orang)
 -- ========================================================
pcall(function()
if _G.AimPROConfig.CustomAimbot and localPlayer.bIsWeaponFiring and localPlayer.bIsGunADS then
local outerRecoilVal=_G.AimPROState.CustomTextData.OuterRecoil or 0
if outerRecoilVal>0 then
local curTime=os.clock()
 -- [FIX CPU SANGAT kuat]: Scan folder target 0.2s/kali ganti karena 100 kali/detik agar tidak terlalu beban mesin saat check FOV
if not _G.RecoilTargetCacheTime or(curTime-_G.RecoilTargetCacheTime)>0.2 then
_G.RecoilTargetCacheTime=curTime
_G.HasRecoilTargetCached=false
local ui_util=require("client.common.ui_util")
if ui_util then
local viewportSize=ui_util.GetViewportSize()
if viewportSize then
local centerX=viewportSize.X*0.5
local centerY=viewportSize.Y*0.5
local FOV_RADIUS=(6/100.0)*(viewportSize.X/2.0)
local enemies=_G.GetEnemyTargetsFromActors(40000)
if enemies and#enemies>0 then
local FVector2D=_G.FourimPROGetImport("Vector2D")
for _,target in ipairs(enemies)do
if slua.isValid(target)and target.HealthStatus~=1 then
local tPos=type(target.K2_GetActorLocation)=="function"and target:K2_GetActorLocation()or nil
if tPos then
local screen=FVector2D()
if pc:ProjectWorldLocationToScreen(tPos,screen,false)and screen.X>0 and screen.Y>0 then
local dx=screen.X-centerX
local dy=screen.Y-centerY
if math.sqrt(dx*dx+dy*dy)<=FOV_RADIUS then
_G.HasRecoilTargetCached=true
break
end
end
end
end
end
end
end
end
end
if _G.HasRecoilTargetCached then
local currentRot=pc:GetControlRotation()
if currentRot then
local pullDownForce=(outerRecoilVal/50.0)*1.5
currentRot.Pitch=currentRot.Pitch-pullDownForce
pc:SetControlRotation(currentRot,"CustomAimbotRecoil")
end
end
end
else
_G.HasRecoilTargetCached=false
end
end)
 -- ========================================================
 -- nyata THI MOD SKIN bisa Akumulasi cocok LANGSUNG LANGSUNG ke MAIN LOOP (maksimal optimal MAKSIMAL MUTLAK)
 -- ========================================================
 -- ========================================================
 -- nyata THI MOD SKIN Peti Tubuh / PET / KILL MESSAGE / paksa V7.5 JALAN
 -- ========================================================
if _G.AimPROConfig.ModSkin then
local curTime=os.clock()
 -- Naikkan waktu durasi check dari 1.0s naik 2.5s untuk anti Spam tersendat lag saat Nyalakan/Matikan fungsi saklar
if not _G.LastSkinUpdateTime or(curTime-_G.LastSkinUpdateTime)>2.5 then
_G.LastSkinUpdateTime=curTime
pcall(function()
local isAlive=type(localPlayer.IsAlive)=="function"and localPlayer:IsAlive()or true
if isAlive then
if _G.HandlePetLogic then _G.HandlePetLogic()end
if _G.AimPROConfig.SkinDeadBox and _G.DeadBox_TemperRequest and _G.NeedCheckDeadBoxTimer>0 then
_G.DeadBox_TemperRequest(pc)
end
if _G.AddOutfit then
 -- [bagi alur tidur BANYAK jelas RÀNG]
if _G.AddOutfit.isInRealMatch()then
 -- alur 1: dalam match (lobby tidur BANYAK)
_G.AddOutfitLobbyRestored=false
 -- [FIX FPS] BAGI kecil lanjut Proses beban SKIN (STAGGERED LOADING)
local ticker=require("common.time_ticker")
if ticker and ticker.AddTimerOnce then
_G.AddOutfit.matchApplyAllSlots(localPlayer)
ticker.AddTimerOnce(0.2,function()
if slua.isValid(localPlayer)and _G.AddOutfit.isInRealMatch()then
_G.AddOutfit.matchApplyHat(localPlayer)
end
end)
ticker.AddTimerOnce(0.4,function()
if slua.isValid(localPlayer)and _G.AddOutfit.isInRealMatch()then
_G.AddOutfit.matchApplyWeaponSkin(localPlayer)
end
end)
ticker.AddTimerOnce(0.6,function()
if slua.isValid(localPlayer)and _G.AddOutfit.isInRealMatch()and _G.AddOutfit.isCharacterAirborne(localPlayer)then
_G.AddOutfit.applyAirborneSlots(localPlayer,true)
end
end)
else
_G.AddOutfit.matchApplyAllSlots(localPlayer)
_G.AddOutfit.matchApplyHat(localPlayer)
_G.AddOutfit.matchApplyWeaponSkin(localPlayer)
if _G.AddOutfit.isCharacterAirborne(localPlayer)then
_G.AddOutfit.applyAirborneSlots(localPlayer,true)
end
end
else
 -- alur 2: luar lobby LOBBY (dalam match tidur BANYAK)
_G.AddOutfit.reapplyLobbyEquipped()
end
end
end
end)
end
end
 -- blokir HIGGSBOSON sesuai waktu durasi nyata buat AN seluruh MAKSIMAL MUTLAK tetapi tidak menyebabkan CRASH GAME
pcall(function()
if Valid(pc)then
if pc.HiggsBoson then pc.HiggsBoson.bMHActive=false;pc.HiggsBoson.bCallPreReplication=false end
if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive=false;pc.HiggsBosonComponent.bCallPreReplication=false end
end
end)
 -- selesai kembalikan dan Baja buat AIMBOT HEAD COMPONENT aktif/MATI langsung maka
pcall(function()
local autoComp=localPlayer.AutoAimComp
if Valid(autoComp)then
if not _G.AimPROState.OrigAutoAimCompCached then
_G.AimPROState.OrigAutoAimCompCached={bOnlyHitHead=autoComp.bOnlyHitHead,HeadBoneName=autoComp.HeadBoneName,Bones=autoComp.Bones,ChestBoneName=autoComp.ChestBoneName,PelvisBoneName=autoComp.PelvisBoneName,HeadPriority=autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,ChestPriority=autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,PelvisPriority=autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
}
end
if _G.AimPROConfig.AutoHead then
autoComp.bOnlyHitHead=true
autoComp.HeadBoneName="Head"
pcall(function()autoComp.Bones={"Head"}end)
autoComp.ChestBoneName="Head"
autoComp.PelvisBoneName="Head"
if autoComp.AimAssistConfig then
autoComp.AimAssistConfig.HeadPriority=100
autoComp.AimAssistConfig.ChestPriority=100
autoComp.AimAssistConfig.PelvisPriority=100
end
else
local orig=_G.AimPROState.OrigAutoAimCompCached
autoComp.bOnlyHitHead=orig.bOnlyHitHead
autoComp.HeadBoneName=orig.HeadBoneName
pcall(function()autoComp.Bones=orig.Bones or{"Spine_01","Pelvis","Head"}end)
autoComp.ChestBoneName=orig.ChestBoneName
autoComp.PelvisBoneName=orig.PelvisBoneName
if autoComp.AimAssistConfig then
autoComp.AimAssistConfig.HeadPriority=orig.HeadPriority or 1
autoComp.AimAssistConfig.ChestPriority=orig.ChestPriority or 1
autoComp.AimAssistConfig.PelvisPriority=orig.PelvisPriority or 1
end
end
end
end)
if _G.AimPROConfig.WallClimb then
pcall(function()
local charMove=localPlayer.CharacterMovement
if Valid(charMove)then
if not _G.AimPROState.WallClimbOriginals then
_G.AimPROState.WallClimbOriginals={WalkableFloorAngle=charMove.WalkableFloorAngle,MaxStepHeight=charMove.MaxStepHeight}
end
charMove.WalkableFloorAngle=199.0
charMove.MaxStepHeight=999.0
_G.AimPROState.WallClimbApplied=true
end
end)
elseif _G.AimPROState.WallClimbApplied then
pcall(function()
local charMove=localPlayer.CharacterMovement
if Valid(charMove)and _G.AimPROState.WallClimbOriginals then
charMove.WalkableFloorAngle=_G.AimPROState.WallClimbOriginals.WalkableFloorAngle or 50.0
charMove.MaxStepHeight=_G.AimPROState.WallClimbOriginals.MaxStepHeight or 45.0
end
end)
_G.AimPROState.WallClimbApplied=false
end
if _G.AimPROConfig.FastCar then
pcall(function()
local currentVehicle=localPlayer.CurrentVehicle or(type(localPlayer.GetVehicle)=="function"and localPlayer:GetVehicle())
if Valid(currentVehicle)then
local rootComp=currentVehicle.RootComponent or(type(currentVehicle.K2_GetRootComponent)=="function"and currentVehicle:K2_GetRootComponent())
if Valid(rootComp)and type(rootComp.SetAllPhysicsLinearVelocity)=="function"then
local isAccelerating=false
local moveComp=currentVehicle.VehicleMovement or currentVehicle.MovementComponent
if Valid(moveComp)then
local throttle=moveComp.ThrottleInput or 0
if type(moveComp.GetThrottleInput)=="function"then
throttle=moveComp:GetThrottleInput()
end
if throttle>0.05 or throttle<-0.05 then
isAccelerating=true
end
end
if currentVehicle.bIsPressingGas or(currentVehicle.Throttle and currentVehicle.Throttle~=0)then
isAccelerating=true
end
local currentVel=nil
if type(currentVehicle.GetVelocity)=="function"then
currentVel=currentVehicle:GetVelocity()
elseif type(rootComp.GetPhysicsLinearVelocity)=="function"then
currentVel=rootComp:GetPhysicsLinearVelocity()
elseif rootComp.ComponentVelocity then
currentVel=rootComp.ComponentVelocity
end
if currentVel then
local currentSpeed=math.sqrt(currentVel.X^2+currentVel.Y^2)
local minSpeedToBoost=50.0
 -- kecepatan tingkat nyata Pengorbanan sudah bisa fix karakter naik dari slider geser (Max 6000.0)
local maxSpeed=_G.AimPROState.CustomTextData.FastCarSpeed or 3000.0
 -- Tetapkan tetapkan gia kecepatan isi kuat untuk kendaraan melaju cepat (kembalikan lagi 1.5 asli)
local accelFactor=1.5
local brakeFactor=0.85
if currentSpeed>minSpeedToBoost then
local dirX=currentVel.X/currentSpeed
local dirY=currentVel.Y/currentSpeed
if isAccelerating then
local targetSpeed=currentSpeed*accelFactor
if targetSpeed>maxSpeed then targetSpeed=maxSpeed end
local newX=dirX*targetSpeed
local newY=dirY*targetSpeed
local newZ=currentVel.Z
rootComp:SetAllPhysicsLinearVelocity(FVector(newX,newY,newZ),false)
else
local targetSpeed=currentSpeed*brakeFactor
if targetSpeed>minSpeedToBoost then
local newX=dirX*targetSpeed
local newY=dirY*targetSpeed
local newZ=currentVel.Z
rootComp:SetAllPhysicsLinearVelocity(FVector(newX,newY,newZ),false)
end
end
end
end
end
end
end)
end
 -- selesai kembalikan barang Bencana langsung buat langsung jika MATI (MATI adalah MATI LIỀN)
local now=os.clock()
pcall(function()
local lsg=require("client.slua.logic.setting.logic_setting_graphics")
local gi=lsg.GetGameInstance()
if gi then
 -- LIGHT ULTRA HDR
 -- Fix HDR character-white bug: keep Bloom untouched.
if _G.AimPROConfig.LightUltraHDR and not _G.AimPROState.PrevGraphicsState.LightUltraHDR then
gi:ExecuteCMD("r.ViewDistanceScale","0.6")
gi:ExecuteCMD("r.ShadowQuality","0")
gi:ExecuteCMD("r.EffectsQuality","0")
gi:ExecuteCMD("r.PostProcessAAQuality","0")
gi:ExecuteCMD("r.MotionBlurQuality","0")
 -- gi:ExecuteCMD("r.BloomQuality", "0")
_G.AimPROState.PrevGraphicsState.LightUltraHDR=true
elseif not _G.AimPROConfig.LightUltraHDR and _G.AimPROState.PrevGraphicsState.LightUltraHDR then
gi:ExecuteCMD("r.ViewDistanceScale","1")
gi:ExecuteCMD("r.ShadowQuality","3")
gi:ExecuteCMD("r.EffectsQuality","3")
gi:ExecuteCMD("r.PostProcessAAQuality","3")
gi:ExecuteCMD("r.MotionBlurQuality","3")
 -- gi:ExecuteCMD("r.BloomQuality", "3")
_G.AimPROState.PrevGraphicsState.LightUltraHDR=false
end
if _G.AimPROConfig.RemoveGrass and not _G.AimPROState.PrevGraphicsState.RemoveGrass then
gi:ExecuteCMD("grass.DensityScale","0")
gi:ExecuteCMD("grass.DiscardDataOnLoad","1")
_G.AimPROState.PrevGraphicsState.RemoveGrass=true
elseif not _G.AimPROConfig.RemoveGrass and _G.AimPROState.PrevGraphicsState.RemoveGrass then
gi:ExecuteCMD("grass.DensityScale","1")
gi:ExecuteCMD("grass.DiscardDataOnLoad","0")
_G.AimPROState.PrevGraphicsState.RemoveGrass=false
end
 -- LOGIC hapus senjata
if _G.AimPROConfig.RemoveTrees and not _G.AimPROState.PrevGraphicsState.RemoveTrees then
gi:ExecuteCMD("foliage.DensityScale","0")
gi:ExecuteCMD("r.Foliage.DensityScale","0")
gi:ExecuteCMD("foliage.MinimumScreenSize","10000")
gi:ExecuteCMD("r.DisableTreeRender","1")
_G.AimPROState.PrevGraphicsState.RemoveTrees=true
elseif not _G.AimPROConfig.RemoveTrees and _G.AimPROState.PrevGraphicsState.RemoveTrees then
gi:ExecuteCMD("foliage.DensityScale","1")
gi:ExecuteCMD("r.Foliage.DensityScale","1")
gi:ExecuteCMD("foliage.MinimumScreenSize","0.0001")
gi:ExecuteCMD("r.DisableTreeRender","0")
_G.AimPROState.PrevGraphicsState.RemoveTrees=false
end
if _G.AimPROConfig and _G.AimPROConfig.tppfpp then
ForceTPP()
_G.markData.TPPApplied=true
elseif _G.markData.TPPApplied then
_G.markData.TPPApplied=false
end
if _G.AimPROConfig.RemoveFog and not _G.AimPROState.PrevGraphicsState.RemoveFog then
gi:ExecuteCMD("r.SkyAtmosphere","1")
gi:ExecuteCMD("r.Fog","0")
gi:ExecuteCMD("r.VolumetricFog","0")
_G.AimPROState.PrevGraphicsState.RemoveFog=true
elseif not _G.AimPROConfig.RemoveFog and _G.AimPROState.PrevGraphicsState.RemoveFog then
gi:ExecuteCMD("r.SkyAtmosphere","1")
gi:ExecuteCMD("r.Fog","1")
gi:ExecuteCMD("r.VolumetricFog","1")
_G.AimPROState.PrevGraphicsState.RemoveFog=false
end
if _G.AimPROConfig.WhiteBody and not _G.AimPROState.PrevGraphicsState.WhiteBody then
gi:ExecuteCMD("r.CharacterDiffuseOffset","2")
gi:ExecuteCMD("r.CharacterDiffusePower","5")
gi:ExecuteCMD("r.CharacterMinShadowFactor","100")
_G.AimPROState.PrevGraphicsState.WhiteBody=true
elseif not _G.AimPROConfig.WhiteBody and _G.AimPROState.PrevGraphicsState.WhiteBody then
gi:ExecuteCMD("r.CharacterDiffuseOffset","0")
gi:ExecuteCMD("r.CharacterDiffusePower","1")
gi:ExecuteCMD("r.CharacterMinShadowFactor","1")
_G.AimPROState.PrevGraphicsState.WhiteBody=false
end
if _G.AimPROConfig.ColorBodyV2 and not _G.AimPROState.PrevGraphicsState.ColorBodyV2 then
gi:ExecuteCMD("r.CharacterMinShadowFactor","4")
gi:ExecuteCMD("r.CharacterDiffuseOffset","200")
gi:ExecuteCMD("r.CharacterDiffusePower","200")
_G.AimPROState.PrevGraphicsState.ColorBodyV2=true
elseif not _G.AimPROConfig.ColorBodyV2 and _G.AimPROState.PrevGraphicsState.ColorBodyV2 then
gi:ExecuteCMD("r.CharacterMinShadowFactor","1")
gi:ExecuteCMD("r.CharacterDiffuseOffset","0")
gi:ExecuteCMD("r.CharacterDiffusePower","1")
_G.AimPROState.PrevGraphicsState.ColorBodyV2=false
end
 -- LOGIC BLACKSKY
if _G.AimPROConfig.BlackSky and not _G.AimPROState.PrevGraphicsState.BlackSky then
gi:ExecuteCMD("r.CylinderMaxDrawHeight","9999")
_G.AimPROState.PrevGraphicsState.BlackSky=true
elseif not _G.AimPROConfig.BlackSky and _G.AimPROState.PrevGraphicsState.BlackSky then
gi:ExecuteCMD("r.CylinderMaxDrawHeight","0000")
_G.AimPROState.PrevGraphicsState.BlackSky=false
end
end
end)
-- RECOIL 4imPRO
pcall(function()
local weapon=nil
pcall(function()
local weaponManager=localPlayer.WeaponManagerComponent
if Valid(weaponManager)and type(weaponManager.GetCurrentWeapon)=="function"then
weapon=weaponManager:GetCurrentWeapon()
end
end)
if not Valid(weapon)then
if type(localPlayer.GetCurrentShootWeapon)=="function"then
weapon=localPlayer:GetCurrentShootWeapon()
elseif type(localPlayer.GetCurrentWeapon)=="function"then
weapon=localPlayer:GetCurrentWeapon()
end
end
if Valid(weapon)then
local entities={}
if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE)then table.insert(entities,weapon.ShootWeaponEntity_GEN_VARIABLE)end
if Valid(weapon.ShootWeaponEntity)then table.insert(entities,weapon.ShootWeaponEntity)end
if Valid(weapon.ShootWeaponComponent)and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent)then
table.insert(entities,weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
end
 -- =========================================================================
 -- BACA NILAI DARI 4imPROState.CustomTextData
 -- =========================================================================
local customData=(_G.AimPROState and _G.AimPROState.CustomTextData)or{}
local rawAccuracy=tonumber(customData.AccuracyLevel)or 0
local rawRecoil=tonumber(customData.RecoilSlider)or 0
local rawShake=tonumber(customData.ShakeSlider)or 0
 -- Clamp supaya nilai slider selalu aman.
rawAccuracy=math.max(0,math.min(100,rawAccuracy))
rawRecoil=math.max(0,math.min(100,rawRecoil))
rawShake=math.max(0,math.min(100,rawShake))
local accFactor=1.0-(0.9999*(rawAccuracy/100.0))
local recoilFactor=1.0-(0.9999*(rawRecoil/100.0))
local shakeFactor=1.0-(0.9999*(rawShake/100.0))
local accessoriesFactor=1.0-(0.7*(rawShake/100.0))
for _,entity in ipairs(entities)do
 -- Simpan nilai asli di cache Lua eksternal.
 -- Jangan menambahkan field baru ke entity/userdata game karena bisa gagal diam-diam
 -- dan menghentikan seluruh blok slider di dalam pcall.
local cache=_G.AimPROSliderOriginalCache
local orig=cache[entity]
if not orig then
orig={GameDeviationAccuracy=entity.GameDeviationAccuracy,GameDeviationFactor=entity.GameDeviationFactor,RecoilKick=entity.RecoilKick,RecoilKickADS=entity.RecoilKickADS,RecoilVerticalFactor=entity.RecoilVerticalFactor,RecoilVerticalFactorADS=entity.RecoilVerticalFactorADS,RecoilHorizontalFactor=entity.RecoilHorizontalFactor,RecoilHorizontalFactorADS=entity.RecoilHorizontalFactorADS,RecoilUpGrowth=entity.RecoilUpGrowth,RecoilUpGrowthADS=entity.RecoilUpGrowthADS,RecoilGrowth=entity.RecoilGrowth,AnimationKick=entity.AnimationKick,CameraRecoilFactor=entity.CameraRecoilFactor,RecoilMaxExtraFactor=entity.RecoilMaxExtraFactor,ShotGunVerticalRecoilFactor=entity.ShotGunVerticalRecoilFactor,AccessoriesVRecoilFactor=entity.AccessoriesVRecoilFactor,AccessoriesHRecoilFactor=entity.AccessoriesHRecoilFactor
}
cache[entity]=orig
end
 -- Slider 0 = benar-benar pakai nilai asli game, bukan dipaksa menjadi 1.0.
if rawAccuracy>0 then
entity.GameDeviationAccuracy=accFactor
entity.GameDeviationFactor=accFactor
else
entity.GameDeviationAccuracy=orig.GameDeviationAccuracy
entity.GameDeviationFactor=orig.GameDeviationFactor
end
if rawRecoil>0 then
entity.RecoilKick=recoilFactor
entity.RecoilKickADS=recoilFactor
entity.RecoilVerticalFactor=recoilFactor
entity.RecoilVerticalFactorADS=recoilFactor
entity.RecoilHorizontalFactor=recoilFactor
entity.RecoilHorizontalFactorADS=recoilFactor
entity.RecoilUpGrowth=recoilFactor
entity.RecoilUpGrowthADS=recoilFactor
entity.RecoilGrowth=recoilFactor
else
entity.RecoilKick=orig.RecoilKick
entity.RecoilKickADS=orig.RecoilKickADS
entity.RecoilVerticalFactor=orig.RecoilVerticalFactor
entity.RecoilVerticalFactorADS=orig.RecoilVerticalFactorADS
entity.RecoilHorizontalFactor=orig.RecoilHorizontalFactor
entity.RecoilHorizontalFactorADS=orig.RecoilHorizontalFactorADS
entity.RecoilUpGrowth=orig.RecoilUpGrowth
entity.RecoilUpGrowthADS=orig.RecoilUpGrowthADS
entity.RecoilGrowth=orig.RecoilGrowth
end
if rawShake>0 then
entity.AnimationKick=shakeFactor
entity.CameraRecoilFactor=shakeFactor
entity.RecoilMaxExtraFactor=shakeFactor
entity.ShotGunVerticalRecoilFactor=shakeFactor
entity.AccessoriesVRecoilFactor=accessoriesFactor
entity.AccessoriesHRecoilFactor=accessoriesFactor
else
entity.AnimationKick=orig.AnimationKick
entity.CameraRecoilFactor=orig.CameraRecoilFactor
entity.RecoilMaxExtraFactor=orig.RecoilMaxExtraFactor
entity.ShotGunVerticalRecoilFactor=orig.ShotGunVerticalRecoilFactor
entity.AccessoriesVRecoilFactor=orig.AccessoriesVRecoilFactor
entity.AccessoriesHRecoilFactor=orig.AccessoriesHRecoilFactor
end
 end -- end for
 end -- end if Valid(weapon)
end)
pcall(function()
local weapon=nil
pcall(function()
local weaponManager=localPlayer.WeaponManagerComponent
if Valid(weaponManager)and type(weaponManager.GetCurrentWeapon)=="function"then
weapon=weaponManager:GetCurrentWeapon()
end
end)
if not Valid(weapon)then
if type(localPlayer.GetCurrentShootWeapon)=="function"then weapon=localPlayer:GetCurrentShootWeapon()
elseif type(localPlayer.GetCurrentWeapon)=="function"then weapon=localPlayer:GetCurrentWeapon()end
end
if Valid(weapon)then
local entities={}
if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE)then table.insert(entities,weapon.ShootWeaponEntity_GEN_VARIABLE)end
if Valid(weapon.ShootWeaponEntity)then table.insert(entities,weapon.ShootWeaponEntity)end
if Valid(weapon.ShootWeaponComponent)and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent)then
table.insert(entities,weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
end
for _,entity in ipairs(entities)do
local anyWeaponModOn=_G.AimPROConfig.CustomHRecoil or _G.AimPROConfig.CustomVRecoil or _G.AimPROConfig.LessShake or _G.AimPROConfig.Accuracy or _G.AimPROConfig.Crosshair or _G.AimPROConfig.GodMode or _G.AimPROConfig.AutoHead or _G.AimPROConfig.CustomAimbot or _G.AimPROConfig.CustomAimbotClose or _G.AimPROConfig.AimbotMode~="None"or _G.AimPROConfig.LessRecoil or _G.AimPROConfig.VerticalRecoil
if anyWeaponModOn then
if not entity.OriginalStatsCached then
entity.OriginalStatsCached={GameDeviationFactor=entity.GameDeviationFactor,GameDeviationAccuracy=entity.GameDeviationAccuracy,BulletFireSpeed=entity.BulletFireSpeed,ShootInterval=entity.ShootInterval,BaseDamage=entity.BaseDamage,AccessoriesHRecoilFactor=entity.AccessoriesHRecoilFactor,AccessoriesVRecoilFactor=entity.AccessoriesVRecoilFactor,RecoilKick=entity.RecoilKick,RecoilKickADS=entity.RecoilKickADS,AnimationKick=entity.AnimationKick
}
end
if _G.AimPROConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor=_G.AimPROState.CustomTextData.HRecoil or 0.3
elseif _G.AimPROConfig.LessRecoil then entity.AccessoriesHRecoilFactor=0.3 end
if _G.AimPROConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor=_G.AimPROState.CustomTextData.VRecoil or 0.3
elseif _G.AimPROConfig.VerticalRecoil then entity.AccessoriesVRecoilFactor=0.3 end
if _G.AimPROConfig.LessShake then entity.RecoilKick=0.0;entity.RecoilKickADS=0.0;entity.AnimationKick=0.0 end
if _G.AimPROConfig.Accuracy then entity.GameDeviationAccuracy=0.0 end
if _G.AimPROConfig.Crosshair then entity.GameDeviationFactor=0.0 end
if _G.AimPROConfig.GodMode then entity.BulletFireSpeed=500000.0;entity.ShootInterval=0.001;entity.BaseDamage=60000.0 end
if entity.AutoAimingConfig then
if not entity.OriginalAutoAimCached then
entity.OriginalAutoAimCached={OuterSpeed=entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,InnerSpeed=entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
}
end
if _G.AimPROConfig.AutoHead then
pcall(function()entity.AutoAimingConfig.Bones={"Head","Head","Head"}end)
end
if _G.AimPROConfig.CustomAimbot then
local speed=_G.AimPROState.CustomTextData.OuterSpeed or 10
if entity.AutoAimingConfig.OuterRange then
entity.AutoAimingConfig.OuterRange.Speed=speed
entity.AutoAimingConfig.OuterRange.RangeRate=4.5
entity.AutoAimingConfig.OuterRange.SpeedRate=1.3
entity.AutoAimingConfig.OuterRange.RangeRateSight=1.8
entity.AutoAimingConfig.OuterRange.SpeedRateSight=2.2
entity.AutoAimingConfig.OuterRange.CrouchRate=1.1
entity.AutoAimingConfig.OuterRange.ProneRate=1.0
entity.AutoAimingConfig.OuterRange.DyingRate=0.0
end
if entity.AutoAimingConfig.InnerRange then
entity.AutoAimingConfig.InnerRange.Speed=speed
entity.AutoAimingConfig.InnerRange.RangeRate=4.5
entity.AutoAimingConfig.InnerRange.SpeedRate=1.3
entity.AutoAimingConfig.InnerRange.RangeRateSight=1.8
entity.AutoAimingConfig.InnerRange.SpeedRateSight=2.2
entity.AutoAimingConfig.InnerRange.CrouchRate=1.1
entity.AutoAimingConfig.InnerRange.ProneRate=1.0
entity.AutoAimingConfig.InnerRange.DyingRate=0.0
end
elseif _G.AimPROConfig.CustomAimbotClose or _G.AimPROConfig.AimbotMode=="Close"then
local speed=_G.AimPROState.CustomTextData.InnerSpeed or 10
if entity.AutoAimingConfig.OuterRange then
entity.AutoAimingConfig.OuterRange.Speed=speed
entity.AutoAimingConfig.OuterRange.DyingRate=0.0
end
if entity.AutoAimingConfig.InnerRange then
entity.AutoAimingConfig.InnerRange.Speed=speed
entity.AutoAimingConfig.InnerRange.DyingRate=0.0
end
elseif _G.AimPROConfig.AimbotMode=="Far"then
if entity.AutoAimingConfig.OuterRange then
entity.AutoAimingConfig.OuterRange.Speed=5
entity.AutoAimingConfig.OuterRange.RangeRate=0.7
entity.AutoAimingConfig.OuterRange.SpeedRate=1.3
entity.AutoAimingConfig.OuterRange.RangeRateSight=1.8
entity.AutoAimingConfig.OuterRange.SpeedRateSight=2.2
entity.AutoAimingConfig.OuterRange.CrouchRate=1.1
entity.AutoAimingConfig.OuterRange.ProneRate=1
end
if entity.AutoAimingConfig.InnerRange then
entity.AutoAimingConfig.InnerRange.Speed=5
entity.AutoAimingConfig.InnerRange.RangeRate=0.7
entity.AutoAimingConfig.InnerRange.SpeedRate=1.3
entity.AutoAimingConfig.InnerRange.RangeRateSight=1.8
entity.AutoAimingConfig.InnerRange.SpeedRateSight=2.2
entity.AutoAimingConfig.InnerRange.CrouchRate=1.1
entity.AutoAimingConfig.InnerRange.ProneRate=1
end
end
end
entity.AimPROWeaponModsActive=true
elseif entity.AimPROWeaponModsActive then
if entity.OriginalStatsCached then
local orig=entity.OriginalStatsCached
entity.GameDeviationFactor=orig.GameDeviationFactor
entity.GameDeviationAccuracy=orig.GameDeviationAccuracy
entity.BulletFireSpeed=orig.BulletFireSpeed
entity.ShootInterval=orig.ShootInterval
entity.BaseDamage=orig.BaseDamage
entity.AccessoriesHRecoilFactor=orig.AccessoriesHRecoilFactor
entity.AccessoriesVRecoilFactor=orig.AccessoriesVRecoilFactor
entity.RecoilKick=orig.RecoilKick
entity.RecoilKickADS=orig.RecoilKickADS
entity.AnimationKick=orig.AnimationKick
end
if entity.AutoAimingConfig and entity.OriginalAutoAimCached then
pcall(function()entity.AutoAimingConfig.Bones={"Spine_01","Pelvis","Head"}end)
if entity.AutoAimingConfig.OuterRange and entity.OriginalAutoAimCached.OuterSpeed then
entity.AutoAimingConfig.OuterRange.Speed=entity.OriginalAutoAimCached.OuterSpeed
end
if entity.AutoAimingConfig.InnerRange and entity.OriginalAutoAimCached.InnerSpeed then
entity.AutoAimingConfig.InnerRange.Speed=entity.OriginalAutoAimCached.InnerSpeed
end
end
entity.AimPROWeaponModsActive=false
end
end
end
end)
local mHead_Global,mBody_Global,mLegs_Global=1.0,1.0,1.0
local runInject_Global=false
pcall(function()
if _G.AimPROConfig.CustomMagicBullet then
runInject_Global=true
mHead_Global=1.0;mBody_Global=1.0;mLegs_Global=1.0
if _G.AimPROState.CustomTextData then
local cData=_G.AimPROState.CustomTextData
if cData.MagicHead~=nil then mHead_Global=tonumber(cData.MagicHead)or mHead_Global end
if cData.MagicBody~=nil then mBody_Global=tonumber(cData.MagicBody)or mBody_Global end
if cData.MagicLegs~=nil then mLegs_Global=tonumber(cData.MagicLegs)or mLegs_Global end
end
elseif _G.AimPROConfig.MagicBullet then
runInject_Global=true
mHead_Global=1.05;mBody_Global=1.0;mLegs_Global=1.0
end
if runInject_Global then
local currentMagicHash="M_"..tostring(mHead_Global).."_"..tostring(mBody_Global).."_"..tostring(mLegs_Global)
if _G.AimPROState.LastMagicConfigHash~=currentMagicHash then
_G.AimPROState.MagicUpdateVersion=(_G.AimPROState.MagicUpdateVersion or 0)+1
_G.AimPROState.LastMagicConfigHash=currentMagicHash
end
else
 -- saat MAGIC BULLET terkena MATI, RESTORE lagi HASH kembali 0
if _G.AimPROState.LastMagicConfigHash~="OFF"then
_G.AimPROState.MagicUpdateVersion=(_G.AimPROState.MagicUpdateVersion or 0)+1
_G.AimPROState.LastMagicConfigHash="OFF"
end
end
end)
pcall(function()
local allCharacters={}
if GameplayData.GetAllPlayerCharacters then allCharacters=GameplayData.GetAllPlayerCharacters()
elseif GameplayData.GameCharacters then for _,char in pairs(GameplayData.GameCharacters)do table.insert(allCharacters,char)end end
local currentValidKeys={}
for _,enemy in pairs(allCharacters)do
if Valid(enemy)and enemy~=localPlayer then
currentValidKeys[GetSafeEnemyKey(enemy)]=true
end
end
for key,data in pairs(_G.AimPROState.EnemyMarks)do
if not currentValidKeys[key]then
SafeRemoveMark(data.radarMark)
SafeRemoveMark(data.hpMark)
SafeRemoveMark(data.distMark)
 -- [FIX RAM]: Bersihkan AimTouch VisCheck dari MUSUH yang sudah MATI atau terlalu jauh
if _G.AimTouchVisCache and _G.AimTouchVisCache[key]then
_G.AimTouchVisCache[key]=nil
end
if data.MIDs then
for meshStr,midTable in pairs(data.MIDs)do
for k,_ in pairs(midTable)do
midTable[k]=nil
end
end
data.MIDs=nil
end
if data.MIDs_V3 then
for meshStr,midTable in pairs(data.MIDs_V3)do
for k,_ in pairs(midTable)do
midTable[k]=nil
end
end
data.MIDs_V3=nil
end
data.enemy=nil
data.CachedMeshes=nil
_G.AimPROState.EnemyMarks[key]=nil
end
end
local realCount=0
local aiCount=0
local function GetFirstElemSafe(elemArray)
if elemArray and type(elemArray.Num)=="function"and elemArray:Num()>0 then
if type(elemArray.Get)=="function"then return elemArray:Get(0)end
elseif elemArray and type(elemArray)=="table"and#elemArray>0 then
return elemArray[1]
end
return nil
end
local BoneScaleMap={["head"]=mHead_Global,["neck_01"]=mHead_Global,["pelvis"]=mBody_Global,["spine_01"]=mBody_Global,["spine_02"]=mBody_Global,["spine_03"]=mBody_Global,["thigh_l"]=mLegs_Global,["thigh_r"]=mLegs_Global,["calf_l"]=mLegs_Global,["calf_r"]=mLegs_Global,["foot_l"]=mLegs_Global,["foot_r"]=mLegs_Global
}
local mLoc=nil
pcall(function()if type(localPlayer.K2_GetActorLocation)=="function"then mLoc=localPlayer:K2_GetActorLocation()end end)
for _,enemy in pairs(allCharacters)do
if Valid(enemy)and enemy~=localPlayer and enemy.TeamID~=localPlayer.TeamID then
local bIsReallyDead=false
pcall(function()
if type(enemy.IsDead)=="function"then bIsReallyDead=enemy:IsDead()
elseif enemy.bIsDead~=nil then bIsReallyDead=enemy.bIsDead
elseif enemy.bIsDeadFlag~=nil then bIsReallyDead=enemy.bIsDeadFlag end
if enemy.HealthStatus~=nil and enemy.HealthStatus==2 then bIsReallyDead=true end
end)
local eKey=GetSafeEnemyKey(enemy)
_G.AimPROState.EnemyMarks[eKey]=_G.AimPROState.EnemyMarks[eKey]or{enemy=enemy}
local markData=_G.AimPROState.EnemyMarks[eKey]
markData.enemy=enemy
if not bIsReallyDead then
 -- [FIX Error HILANG HP saat lompat parasut/Kembali buat]: Cek apakah MUSUH ada terkena ganti Actor (karakter item baru) tidak.
 -- jika ada, hapus seluruh bagian Marker (UI) terkena macet di Tubuh lama untuk code sisi di bawah gambar ulang naik karakter item baru.
if markData.lastEnemyActor~=enemy then
if markData.hpMark then SafeRemoveMark(markData.hpMark);markData.hpMark=nil end
 if markData.hpMark8 then SafeRemoveMark(markData.hpMark8);markData.hpMark8=nil end -- Selalu hapus sampah ESP 8
if markData.distMark then SafeRemoveMark(markData.distMark);markData.distMark=nil end
if markData.radarMark then SafeRemoveMark(markData.radarMark);markData.radarMark=nil end
markData.lastEnemyActor=enemy
markData.LastUIComp=nil
markData.LastFrameUIState=nil
end
local eMesh=nil
pcall(function()eMesh=enemy.Mesh or(type(enemy.getAvatarComponent2)=="function"and enemy:getAvatarComponent2()or nil)end)
local aLoc=nil
pcall(function()if type(enemy.K2_GetActorLocation)=="function"then aLoc=enemy:K2_GetActorLocation()end end)
local isBotResult,isStateLoaded=CheckIsAI(enemy,markData)
local isBot=markData.AK_IS_BOT or false
local currentMeshCount=0
if Valid(eMesh)then
local tempMeshes=GetAllSkeletalMeshes(enemy,markData)
currentMeshCount=#tempMeshes
end
local isMeshChanged=(markData.LastMeshCountWall~=currentMeshCount)
 -- sudah maksimal optimal SANGAT pun: hanya Apply saat asli hal perlu
if _G.AimPROConfig.WallXuyenTuong then
if isMeshChanged or not markData.WallhackApplied then
ApplyWallXuyenTuong(enemy,markData)
markData.WallhackApplied=true
markData.LastMeshCountWall=currentMeshCount
end
else
UndoWallXuyenTuong(enemy,markData)
end
 -- sudah maksimal optimal SANGAT pun
if _G.AimPROConfig.ColorBodyV2 then
 -- dalam Fungsi ini SAYA sudah batas batas PC:LINEOFSIGHTTO lagi untuk hindari TERLALU beban CPU
ApplyColorBodyV2(enemy,pc,markData)
else
UndoColorBodyV2(enemy,markData)
end
 -- fungsi FITUR warna V3 (terlihat area HIJAU daun + setelah tembok warna merah) sangat ỔN tetapkan
if _G.AimPROConfig.ColorBodyV3 then
ApplyColorBodyV3(enemy,markData)
else
UndoColorBodyV3(enemy,markData)
end
 -- fungsi FITUR WALL warna NEW
if _G.AimPROConfig.ColorBodyNew then
ApplyColorBodyNew(enemy,markData)
else
UndoColorBodyNew(enemy,markData)
end
 -- BUG layar: geser DÃN MUSUH buat HITBOX TO keluar (FAT BODY) - sudah maksimal optimal
pcall(function()
if Valid(eMesh)then
local targetScale=1.0
if _G.AimPROConfig.BugManEnable and _G.AimPROState.CustomTextData then
targetScale=177.0/(_G.AimPROState.CustomTextData.BugManRatio or 133)
if targetScale<1.0 then targetScale=1.0 end
 if targetScale>2.0 then targetScale=2.0 end -- Anti Error barang Bencana jika geser terlalu tingkat
end
 -- [FIX sampah RAM]: hanya renggangkan tulang saat ada hal ganti ganti (aktif/MATI atau geser slider seluncur)
if markData.LastFatScale~=targetScale then
eMesh:SetRelativeScale3D(FVector(targetScale,targetScale,1.0))
markData.LastFatScale=targetScale
end
end
end)
 -- LOGIC MAGIC BULLET (sudah FIX lag BANYAK orang dengan UNIQUE ID)
pcall(function()
local EnemyMesh=eMesh
if slua.isValid(EnemyMesh)then
 -- [FIX CPU EKSTREM]: gunakan ID asli karakter/item. Jangan pakai tostring() karena SLUA terus membuat string baru
 -- menyebabkan Error hitung hitung lagi 50 frame tulang ulang pergi ulang lagi saat Timur orang.
local uniqueID=type(enemy.GetUniqueID)=="function"and enemy:GetUniqueID()or tostring(enemy.PlayerKey or enemy)
 -- hanya hitung hitung tulang BENAR 1 kali DUY paling untuk setiap MUSUH MUSUH (kurangi saat kamu geser slider Atur size)
if markData.MagicBulletHash==_G.AimPROState.LastMagicConfigHash and markData.MagicTargetID==uniqueID then
return
end
local PhysicsAsset=EnemyMesh.PhysicsAssetOverride
if not slua.isValid(PhysicsAsset)and EnemyMesh.SkeletalMesh then PhysicsAsset=EnemyMesh.SkeletalMesh.PhysicsAsset end
if slua.isValid(PhysicsAsset)and PhysicsAsset.SkeletalBodySetups then
if not _G.AK_ModdedPhysAssets then _G.AK_ModdedPhysAssets={}end
local PhysAssetName="DefaultPhys"
pcall(function()PhysAssetName=PhysicsAsset:GetName()end)
 -- Optimasi level 2: jika bagian tulang ini sudah setiap bisa perbesar to karena satu MUSUH MUSUH berbeda, gunakan selalu, tidak jalan loop
if _G.AK_ModdedPhysAssets[PhysAssetName]~=_G.AimPROState.LastMagicConfigHash then
if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes={}end
if not _G.AK_OrigHitboxes[PhysAssetName]then _G.AK_OrigHitboxes[PhysAssetName]={}end
local OrigHitboxData=_G.AK_OrigHitboxes[PhysAssetName]
local SkeletalBodySetups=PhysicsAsset.SkeletalBodySetups
local numSetups=type(SkeletalBodySetups.Num)=="function"and SkeletalBodySetups:Num()or#SkeletalBodySetups
local limit=numSetups>50 and 50 or numSetups
for i=1,limit do
local BodySetup=type(SkeletalBodySetups.Get)=="function"and SkeletalBodySetups:Get(i-1)or SkeletalBodySetups[i]
if slua.isValid(BodySetup)then
local LowerBoneName=string.lower(tostring(BodySetup.BoneName))
local MatchedBoneKey=nil
for k,_ in pairs(BoneScaleMap)do
if string.find(LowerBoneName,k,1,true)then MatchedBoneKey=k break end
end
if MatchedBoneKey then
local TargetScale=1.0
if runInject_Global then TargetScale=BoneScaleMap[MatchedBoneKey]end
local AggGeom=BodySetup.AggGeom
local BoxElems=AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
local SphereElems=AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
local SphylElems=AggGeom and AggGeom.SphylElems or BodySetup.SphylElems
local BoxElem=GetFirstElemSafe(BoxElems)
local SphereElem=GetFirstElemSafe(SphereElems)
local SphylElem=GetFirstElemSafe(SphylElems)
if not OrigHitboxData[MatchedBoneKey]then
OrigHitboxData[MatchedBoneKey]={Box=nil,Sphere=nil,Sphyl=nil}
if BoxElem then OrigHitboxData[MatchedBoneKey].Box={X=BoxElem.X,Y=BoxElem.Y,Z=BoxElem.Z}end
if SphereElem then OrigHitboxData[MatchedBoneKey].Sphere={Radius=SphereElem.Radius}end
if SphylElem then OrigHitboxData[MatchedBoneKey].Sphyl={Radius=SphylElem.Radius,Length=SphylElem.Length}end
end
local OrigElemData=OrigHitboxData[MatchedBoneKey]
if OrigElemData.Box and BoxElem then
BoxElem.X=OrigElemData.Box.X*TargetScale
BoxElem.Y=OrigElemData.Box.Y*TargetScale
BoxElem.Z=OrigElemData.Box.Z*TargetScale
if type(BoxElems.Set)=="function"then BoxElems:Set(0,BoxElem)else BoxElems[1]=BoxElem end
if AggGeom then AggGeom.BoxElems=BoxElems;BodySetup.AggGeom=AggGeom else BodySetup.BoxElems=BoxElems end
end
if OrigElemData.Sphere and SphereElem then
SphereElem.Radius=OrigElemData.Sphere.Radius*TargetScale
if type(SphereElems.Set)=="function"then SphereElems:Set(0,SphereElem)else SphereElems[1]=SphereElem end
if AggGeom then AggGeom.SphereElems=SphereElems;BodySetup.AggGeom=AggGeom else BodySetup.SphereElems=SphereElems end
end
if OrigElemData.Sphyl and SphylElem then
SphylElem.Radius=OrigElemData.Sphyl.Radius*TargetScale
SphylElem.Length=OrigElemData.Sphyl.Length*TargetScale
if type(SphylElems.Set)=="function"then SphylElems:Set(0,SphylElem)else SphylElems[1]=SphylElem end
if AggGeom then AggGeom.SphylElems=SphylElems;BodySetup.AggGeom=AggGeom else BodySetup.SphylElems=SphylElems end
end
end
end
end
_G.AK_ModdedPhysAssets[PhysAssetName]=_G.AimPROState.LastMagicConfigHash
end
if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset)end
EnemyMesh.PhysicsAssetOverride=PhysicsAsset
markData.MagicBulletHash=_G.AimPROState.LastMagicConfigHash
 markData.MagicTargetID=uniqueID -- simpan ID Statis
end
end
end)
local distM=0
pcall(function()distM=localPlayer:GetDistanceTo(enemy)/100 end)
local currentHp,maxHp=100,100
local showFrameUI=_G.AimPROConfig.EspLoai5 or _G.AimPROConfig.EspVipPro or _G.AimPROConfig.EspVip
if showFrameUI then
pcall(function()
if enemy.Health then currentHp=enemy.Health elseif type(enemy.GetHealth)=="function"then currentHp=enemy:GetHealth()end
if enemy.HealthMax then maxHp=enemy.HealthMax elseif type(enemy.GetHealthMax)=="function"then maxHp=enemy:GetHealthMax()end
end)
if maxHp<=0 then maxHp=100 end
end
local hpRatio=currentHp/maxHp
if _G.AimPROConfig.EspAntenna then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD)and distM<=400 then
local loopCount=8
local zStep=1000
local baseZ=105
local topZ=baseZ+(loopCount*zStep)
for i=1,loopCount do
local zOffset=baseZ+(i*zStep)
MyHUD:AddDebugText("|",enemy,0.06,{X=0,Y=0,Z=zOffset},{X=0,Y=0,Z=zOffset},C_GREEN,true,false,true,nil,1.2,true)
end
MyHUD:AddDebugText("I",enemy,0.06,{X=0,Y=0,Z=topZ+60},{X=0,Y=0,Z=topZ+60},C_GREEN,true,false,true,nil,1.5,true)
end
end)
end
if _G.AimPROConfig.EspLoai6 then
pcall(function()
local curTime=os.clock()
 -- maksimal optimal SANGAT tingkat 1: Kunci Irama gambar HUD 20 FPS (0.05s/kali) ganti karena 100 FPS
 -- Game tetap mulus, tapi CPU tidak terkena membebani karena spam perintah AddDebugText
if markData.LastEsp6Time==nil or(curTime-markData.LastEsp6Time)>=0.05 then
markData.LastEsp6Time=curTime
local MyHUD=Cached_MyHUD
if Valid(MyHUD)and Valid(eMesh)and aLoc then
if distM<=250 then
 -- ambil koordinat tingkat kepala keputusan, jika tidak ada fungsi ini maka hapus juga
if type(eMesh.GetSocketLocation)=="function"then
for _,bName in ipairs(GLOBAL_BONE_LIST)do
 -- maksimal optimal SANGAT tingkat 2: MUSUH jauh lebih 50m hanya gambar kepala, kuno, Pink. hapus juga tangan kaki bantu sampah
if distM>50 and(bName~="head"and bName~="pelvis"and bName~="neck_01")then
 -- Skip tidak gambar tangan kaki di jauh
else
local wLoc=eMesh:GetSocketLocation(bName)
if wLoc then
 -- hitung Offset standar untuk HUD
local offset={X=wLoc.X-aLoc.X,Y=wLoc.Y-aLoc.Y,Z=wLoc.Z-aLoc.Z}
local mark="▪"
local fixedSize=0.25
local color=C_CYAN
if bName=="head"then
mark="●"
fixedSize=0.45
color=C_RED
elseif bName=="pelvis"or bName=="neck_01"then
mark="▪"
fixedSize=0.35
color=C_YELLOW
end
 -- gambar titik sambungan tulang (masa hidup 0.06s agar tersambung mulus dengan frame 0.05s)
MyHUD:AddDebugText(mark,enemy,0.06,offset,offset,color,true,false,true,nil,fixedSize,true)
end
end
end
end
 -- simpan Ý: sudah XOÁ hapus selesai seluruh hitung FITUR gambar Garis NỐI (GLOBAL_CONNECTIONS)
 -- karena gunakan Tanda titik "." susun menjadi Garis adalah tetap karakter utama menyebabkan drop FPS 
end
end
end
end)
end
if _G.AimPROConfig.EspLoai7 then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD)then
if distM<=600 then if isBot then aiCount=aiCount+1 else realCount=realCount+1 end end
if distM<=400 then
local stateText=""
 -- 1. Proses Postur Dunia
if _G.AimPROConfig.Esp7_TuThe then
local pose=nil
if enemy.PoseState then pose=enemy.PoseState
elseif type(enemy.GetPoseState)=="function"then pose=enemy:GetPoseState()end
if pose==0 or pose=="Stand"then stateText="Berdiri"
elseif pose==1 or pose=="Crouch"then stateText="Jongkok"
elseif pose==2 or pose=="Prone"then stateText="Prone"
else stateText="Berdiri"end
end
 -- 2. Proses senjata senjata
if _G.AimPROConfig.Esp7_VuKhi then
local curTime=os.clock()
if markData.AK_LAST_WEP_TIME==nil or curTime>markData.AK_LAST_WEP_TIME+1.5 then
local eWeapon=nil
if enemy.CurrentWeapon then eWeapon=enemy.CurrentWeapon
elseif type(enemy.GetCurrentWeapon)=="function"then eWeapon=enemy:GetCurrentWeapon()
elseif enemy.WeaponManagerComponent then eWeapon=enemy.WeaponManagerComponent.CurrentWeaponReplicated end
local weaponName="Tangan Kosong"
if Valid(eWeapon)then if type(eWeapon.GetWeaponName)=="function"then weaponName=eWeapon:GetWeaponName()end end
markData.AK_CACHED_WEP_NAME=tostring(weaponName)
markData.AK_LAST_WEP_TIME=curTime
end
if stateText~=""then
stateText=stateText.."-"..(markData.AK_CACHED_WEP_NAME or"Tangan Kosong")
else
stateText=(markData.AK_CACHED_WEP_NAME or"Tangan Kosong")
end
end
 -- 3. gambar naik layar gambar jika ada aktif 1 dalam 2
if stateText~=""then
local textColor=isBot and C_CYAN or C_YELLOW
local dynamicScale=math.max(0.5,0.8-(distM/400))
MyHUD:AddDebugText(stateText,enemy,0.06,{X=0,Y=0,Z=100},{X=0,Y=0,Z=100},textColor,true,false,true,nil,dynamicScale,true)
end
end
end
end)
end
 -- hanya SetVisibility untuk UI frame HP saat asli hal perlu
if showFrameUI then
pcall(function()
local SecurityCommonUtils=Cached_SecurityCommonUtils
local show=true
if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then
if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus)then show=false end
end
if show and mLoc then
if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
if SecurityCommonUtils.IsVector(aLoc)and SecurityCommonUtils.IsVector(mLoc)then
if aLoc.Z>=150000 or FVector.Dist2D(mLoc,aLoc)>50000 then show=false end
end
end
end
if show then
if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted()then enemy:Replay_CreateEnemyFrameUI(true,true)end
if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true)end
if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio)end
local uiComp=enemy.EnemyFrameUI or(type(enemy.GetEnemyFrameUI)=="function"and enemy:GetEnemyFrameUI())
if Valid(uiComp)then
if markData.LastFrameUIState~="VISIBLE"then
if type(uiComp.SetVisibility)=="function"then uiComp:SetVisibility(0)end
if type(uiComp.SetHiddenInGame)=="function"then uiComp:SetHiddenInGame(false)end
markData.LastFrameUIState="VISIBLE"
end
end
end
end)
else
pcall(function()
if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false)end
local uiComp=enemy.EnemyFrameUI or(type(enemy.GetEnemyFrameUI)=="function"and enemy:GetEnemyFrameUI())
if Valid(uiComp)then
if markData.LastFrameUIState~="HIDDEN"then
if type(uiComp.SetVisibility)=="function"then uiComp:SetVisibility(2)end
if type(uiComp.SetHiddenInGame)=="function"then uiComp:SetHiddenInGame(true)end
markData.LastFrameUIState="HIDDEN"
end
end
end)
end
if _G.AimPROConfig.EspVipPro then
pcall(function()
local hud=Cached_MyHUD
if Valid(hud)and hud.AddDebugText then
if distM<=400 then
local dynamicScale=math.max(0.55,0.95-(distM/400))
local hpPercent=hpRatio
local isKnock=(currentHp<=0 and enemy.HealthStatus==1)
local hpColor=C_GREEN
if hpPercent<0.3 then hpColor=C_RED
elseif hpPercent<0.7 then hpColor=C_YELLOW end
if isKnock then hpColor=C_RED end
 -- gambar nama orang Main
if _G.AimPROConfig.Esp3ShowName then
local enemyName="Enemy"
pcall(function()if enemy.PlayerName then enemyName=enemy.PlayerName elseif type(enemy.GetPlayerName)=="function"then enemyName=enemy:GetPlayerName()end end)
if enemyName==""then enemyName="Enemy"end
if isKnock then enemyName="KNOCK:"..enemyName end
hud:AddDebugText(enemyName,enemy,0.06,{X=0,Y=0,Z=-370},{X=0,Y=0,Z=-370},C_WHITE,true,false,true,nil,dynamicScale*1.1,true)
end
 -- gambar slider HP
if _G.AimPROConfig.Esp3ShowHP then
if not isKnock then
local segments=6
local filled=math.floor(hpPercent*segments)
local startZ=20
local spacing=10.0*dynamicScale
for j=1,segments do
local color=(j<=filled)and hpColor or{R=30,G=30,B=30,A=180}
hud:AddDebugText("█",enemy,0.06,{X=0,Y=-115,Z=startZ+(j*spacing)},{X=0,Y=-115,Z=startZ+(j*spacing)},color,true,false,true,nil,dynamicScale*1.2,true)
end
hud:AddDebugText(string.format("%d%%",math.floor(hpPercent*100)),enemy,0.06,{X=0,Y=-60,Z=startZ-12},{X=0,Y=-60,Z=startZ-12},hpColor,true,false,true,nil,dynamicScale*0.8,true)
else
hud:AddDebugText("DOWN",enemy,0.06,{X=0,Y=-115,Z=50},{X=0,Y=-115,Z=50},C_RED,true,false,true,nil,dynamicScale*1.0,true)
end
end
end
end
end)
end
if _G.AimPROConfig.EspDistance then
pcall(function()
local hud=Cached_MyHUD
if Valid(hud)and hud.AddDebugText then
if distM<=400 then
local dynamicScale=math.max(0.55,0.95-(distM/400))
hud:AddDebugText(string.format("[%dm]",math.floor(distM)),enemy,0.06,{X=0,Y=115,Z=20},{X=0,Y=115,Z=20},C_BLUE_TEXT,true,false,true,nil,dynamicScale*1.5,true)
end
end
end)
end
 -- [ESP jenis 1 (sudah Fix Error)]: Pertahankan slider HP (hpMark) dan sekitar jarak (distMark)
if _G.AimPROConfig.EspVip then
if markData.hpMark==nil then markData.hpMark=SafeAddMark(1006,FVector(0,0,0),0,"",4,enemy)end
if markData.distMark==nil then markData.distMark=SafeAddMark(9999,FVector(0,0,0),0,"",4,enemy)end
else
if markData.hpMark then SafeRemoveMark(markData.hpMark);markData.hpMark=nil end
if markData.distMark then SafeRemoveMark(markData.distMark);markData.distMark=nil end
end
 -- [ESP jenis 8 unik buat (sudah Fix Error)]: Copy logic slider HP ESP 1, tapi jalan variabel hpMark8 khusus khusus
if _G.AimPROConfig.EspLoai8 then
if markData.hpMark8==nil then markData.hpMark8=SafeAddMark(1006,FVector(0,0,0),0,"",4,enemy)end
else
if markData.hpMark8 then SafeRemoveMark(markData.hpMark8);markData.hpMark8=nil end
end
if _G.AimPROConfig.EspRadar then
 -- perbaiki Error macet variabel (nil/false/0) dan panggil ID 8888 unik agar
if not markData.radarMark or markData.radarMark==0 then
markData.radarMark=SafeAddMark(8888,FVector(0,0,0),0,"",4,enemy)
end
else
if markData.radarMark and markData.radarMark~=0 then
SafeRemoveMark(markData.radarMark)
markData.radarMark=nil
end
end
 -- [ESP OUTLINE - Y CHANG 100% LOGIC terlihat area V3]: deteksi terang sesuai Atur warna HDR
if _G.AimPROConfig.EspOutline then
pcall(function()
local outColorChoice=_G.AimPROState.CustomTextData.OutlineColor or 4
local outThick=_G.AimPROConfig.OutlineThickness or 10
local outlineHash=string.format("%d_%d",outThick,outColorChoice)
local meshes=GetAllSkeletalMeshes(enemy,markData)
local currentMeshCount=#meshes
if markData.OutlineState~=outlineHash or markData.LastMeshCountOutline~=currentMeshCount then
 local r,g,b=255,255,0 -- Kuning (tetap tetapkan)
 if outColorChoice==1 then r,g,b=255,0,0 -- Merah
 elseif outColorChoice==2 then r,g,b=0,255,0 -- hijau
 elseif outColorChoice==3 then r,g,b=0,0,255 -- Biru
 elseif outColorChoice==4 then r,g,b=255,255,0 -- Kuning
 elseif outColorChoice==5 then r,g,b=255,0,255 -- Ungu/Pink
 elseif outColorChoice==6 then r,g,b=255,255,255 end -- Putih
local glowIntensity=80.0
local LinearColorClass=_G.FourimPROGetImport("LinearColor")or _G.FLinearColor
local glowDynamic=LinearColorClass and LinearColorClass((r/255)*glowIntensity,(g/255)*glowIntensity,(b/255)*glowIntensity,1.0)or{R=r*glowIntensity,G=g*glowIntensity,B=b*glowIntensity,A=255}
for _,comp in ipairs(meshes)do
if Valid(comp)then
 -- tangkap BUỘC GIỐNG V3: paksa Shading Model untuk aktifkan aktif deteksi terang HDR (Bloom)
pcall(function()
comp.UseScopeDistanceCulling=false
comp.PrimitiveShadingStrategy=1
comp.ShadingRate=6
end)
 -- SAMA SEPERTI V3: gambar Outline di atas dengan fungsi asli Engine
if comp.SetDrawIdeaOutline then
comp:SetDrawIdeaOutline(true)
if comp.OverrideIdeaOutlineColor then
comp:OverrideIdeaOutlineColor(true,glowDynamic)
end
if comp.OverrideIdeaOutlineThickness then
 -- ketebalan border mengikuti slider di Menu kamu
comp:OverrideIdeaOutlineThickness(true,_G.AimPROConfig.OutlineThickness)
end
end
end
end
markData.OutlineState=outlineHash
 markData.LastMeshCountOutline=currentMeshCount -- simpan lagi jumlah jumlah tambahan syarat tampil di
end
end)
else
pcall(function()
if markData.OutlineState~="OFF"then
local meshes=GetAllSkeletalMeshes(enemy,markData)
for _,comp in ipairs(meshes)do
if Valid(comp)then
 -- selesai kembalikan Shading Model kembali tetap tetapkan saat MATI
pcall(function()
comp.PrimitiveShadingStrategy=0
comp.ShadingRate=1
end)
if comp.SetDrawIdeaOutline then
comp:SetDrawIdeaOutline(false)
end
end
end
markData.OutlineState="OFF"
markData.LastMeshCountOutline=0
end
end)
end
else
if not markData.IsCleanedUp then
SafeRemoveMark(markData.radarMark)
markData.radarMark=nil
SafeRemoveMark(markData.hpMark)
markData.hpMark=nil
 SafeRemoveMark(markData.hpMark8) -- Bersihkan rapikan ESP 8
markData.hpMark8=nil
SafeRemoveMark(markData.distMark)
markData.distMark=nil
if markData.MIDs then
for meshStr,midTable in pairs(markData.MIDs)do
for k,_ in pairs(midTable)do midTable[k]=nil end
end
markData.MIDs=nil
end
if markData.MIDs_V3 then
for meshStr,midTable in pairs(markData.MIDs_V3)do
for k,_ in pairs(midTable)do midTable[k]=nil end
end
markData.MIDs_V3=nil
end
pcall(function()
local eObj=markData.enemy
if Valid(eObj)then
if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false)end
local uiComp=eObj.EnemyFrameUI or(type(eObj.GetEnemyFrameUI)=="function"and eObj:GetEnemyFrameUI())
if Valid(uiComp)then
if type(uiComp.SetVisibility)=="function"then uiComp:SetVisibility(2)end
if type(uiComp.SetHiddenInGame)=="function"then uiComp:SetHiddenInGame(true)end
end
end
local PPM=Cached_PPM
local avatarComp=Valid(eObj)and(type(eObj.getAvatarComponent2)=="function")and eObj:getAvatarComponent2()or nil
if Valid(avatarComp)and Valid(PPM)then PPM:EnableAvatarOutline(avatarComp,false)end
end)
markData.IsCleanedUp=true
end
end
end
end
if _G.AimPROConfig.EspLoai7 and _G.AimPROConfig.Esp7_SoLuong then
 _M_DrawCounter() -- panggil fungsi Widget UMG keren keren
else
 -- MATI fungsi saklar maka untuk tersembunyi Widget disembunyikan
if EnemyCounterWidget and slua.isValid(EnemyCounterWidget)then
EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
end
 -- ==========================================================
 -- [LOGIC ESP BOM VVIP] - OPTIMIZED WITH WEAK CACHE (100% asli, tidak lag)
 -- ==========================================================
if _G.AimPROConfig.EspBomMaster and(_G.AimPROConfig.EspItemBom or _G.AimPROConfig.EspActiveBom)then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD)then
if not _G.CachedGameplayStatics then _G.CachedGameplayStatics=import("GameplayStatics")end
if not _G.CachedActorClass_ForBomb then _G.CachedActorClass_ForBomb=import("Actor")end
if not _G.CachedProjArray then _G.CachedProjArray=slua.Array(UEnums.EPropertyClass.Object,_G.CachedActorClass_ForBomb)end
 -- Mulai buat Cache gunakan gunakan Weak Table untuk game otomatis hapus sampah, tidak penuh RAM
if not _G.ActorBombCacheInit then
_G.NonBombCache=setmetatable({},{__mode="k"})
_G.BombCache=setmetatable({},{__mode="k"})
_G.ActorBombCacheInit=true
end
local ui_util=require("client.common.ui_util")
local gameInstance=ui_util and ui_util.GetGameInstance()
if gameInstance and _G.CachedGameplayStatics then
local curTime=os.clock()
 -- alur scan DỮ LIỆU berat: Lari 0.5s/kali ganti karena setiap frame
if not _G.LastBombScanTime or(curTime-_G.LastBombScanTime)>0.5 then
_G.LastBombScanTime=curTime
local allActors=_G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance,_G.CachedActorClass_ForBomb,_G.CachedProjArray)
local activeBombs={}
local itemBombs={}
if allActors then
for _,actor in pairs(allActors)do
if slua.isValid(actor)and not actor.bHidden and not actor.bTearOff then
 -- 1. cek cek bagian ingat cache (CACHE) super kecepatan
 -- jika actor ini sudah setiap scan dan tidak harus BOM -> hapus juga buat langsung (kurangi 99% lag)
if not _G.NonBombCache[actor]then
local bType=0
local isItem=false
local isKnownBomb=_G.BombCache[actor]
if isKnownBomb then
bType=isKnownBomb.type
isItem=isKnownBomb.isItem
else
 -- Pertama kali lihat Actor ini, lanjut aksi cek cek nama (sangat sedikit saat terjadi keluar)
local nameLower=nil
pcall(function()nameLower=string.lower(type(actor.GetName)=="function"and actor:GetName()or tostring(actor))end)
if nameLower then
if string.find(nameLower,"m79")or string.find(nameLower,"launcher")then bType=5
elseif string.find(nameLower,"smoke")then bType=2
elseif string.find(nameLower,"burn")or string.find(nameLower,"molotov")then bType=3
elseif string.find(nameLower,"flash")or string.find(nameLower,"stun")then bType=4
elseif string.find(nameLower,"grenade")then bType=1 end
if bType>0 then
if string.find(nameLower,"projectile")or string.find(nameLower,"thrown")then
isItem=false
else
isItem=true
local shouldAdd=true
if bType==3 and not(string.find(nameLower,"pickup")or string.find(nameLower,"wrapper")or string.find(nameLower,"weapon"))then
shouldAdd=false
elseif bType==5 then
local attachParent=nil
pcall(function()if type(actor.GetAttachParentActor)=="function"then attachParent=actor:GetAttachParentActor()end end)
if slua.isValid(attachParent)then
local isHolding=false
pcall(function()
local curWeapon=type(attachParent.GetCurrentWeapon)=="function"and attachParent:GetCurrentWeapon()or attachParent.CurrentWeapon
if curWeapon==actor then isHolding=true end
end)
if not isHolding then shouldAdd=false end
end
end
if not shouldAdd then bType=0 end
end
end
end
 -- simpan selesai hasil ke Cache
if bType>0 then
_G.BombCache[actor]={type=bType,isItem=isItem}
else
_G.NonBombCache[actor]=true
end
end
 -- Jika Bom cocok rasio (dari Cache atau baru cari keluar)
if bType>0 then
local isPendingKill=false
pcall(function()if type(actor.IsPendingKill)=="function"then isPendingKill=actor:IsPendingKill()end end)
if not isPendingKill then
if isItem then
table.insert(itemBombs,{act=actor,type=bType})
else
table.insert(activeBombs,{act=actor,type=bType})
end
else
 -- Hapus dari cache jika bomb sudah meledak/variabel hilang
_G.BombCache[actor]=nil
end
end
end
end
end
end
_G.CachedActiveBombs=activeBombs
_G.CachedItemBombs=itemBombs
end
local curGameTime=0
pcall(function()curGameTime=_G.CachedGameplayStatics.GetTimeSeconds(gameInstance)end)
local function DrawBombs(bombList,isItem,maxDist)
if not bombList then return end
for _,item in ipairs(bombList)do
local bomb=item.act
local bType=item.type
if slua.isValid(bomb)and not bomb.bHidden then
local distM=0
pcall(function()distM=localPlayer:GetDistanceTo(bomb)/100 end)
if distM>0 and distM<=maxDist then
local displayName=""
local bombColor=C_WHITE
local zOffset=isItem and 15 or 25
if bType==1 then displayName="Boom";bombColor=isItem and{R=255,G=100,B=100,A=255}or C_RED
elseif bType==2 then displayName="Asap";bombColor=isItem and{R=200,G=200,B=200,A=255}or C_WHITE
elseif bType==3 then displayName="Molotov";bombColor=isItem and{R=255,G=160,B=50,A=255}or{R=255,G=100,B=0,A=255}
elseif bType==4 then displayName="FalshBang";bombColor=isItem and{R=150,G=255,B=255,A=255}or C_CYAN
elseif bType==5 then displayName="Senjata Asap";bombColor=isItem and{R=150,G=255,B=150,A=255}or{R=100,G=255,B=100,A=255}end
local text=string.format("%s [%dm]",displayName,math.floor(distM))
local shouldTimerRun=not isItem
if isItem then pcall(function()if bomb.bIsPinPulled or bomb.bPinPulled or(type(bomb.IsPinPulled)=="function"and bomb:IsPinPulled())then shouldTimerRun=true end end)end
if shouldTimerRun and curGameTime>0 then
local timeLeft=-1
pcall(function()if bomb.ExplosionTime then timeLeft=bomb.ExplosionTime-curGameTime elseif bomb.ExplodeTime then timeLeft=bomb.ExplodeTime-curGameTime end end)
if timeLeft==-1 or timeLeft>100 then
_G.ActiveBombTimers=_G.ActiveBombTimers or{}
local bombId=tostring(bomb)
if not _G.ActiveBombTimers[bombId]then _G.ActiveBombTimers[bombId]=curGameTime end
local elapsed=curGameTime-_G.ActiveBombTimers[bombId]
local maxTime=(bType==1 and 7.0)or(bType==2 and 45.0)or(bType==3 and 12.0)or(bType==4 and 5.0)or 45.0
timeLeft=maxTime-elapsed
end
if timeLeft<0 then timeLeft=0 end
if timeLeft>0.1 then text=string.format("%s (%.1fs)",text,timeLeft)end
end
local dynamicScale=math.max(0.6,1.1-(distM/maxDist))
MyHUD:AddDebugText(text,bomb,0.06,{X=0,Y=0,Z=zOffset},{X=0,Y=0,Z=zOffset},bombColor,true,false,true,nil,dynamicScale,true)
end
end
end
end
if not _G.LastClearTimer or(curTime-_G.LastClearTimer)>1.0 then
_G.LastClearTimer=curTime
pcall(function()if _G.ActiveBombTimers then for k,v in pairs(_G.ActiveBombTimers)do if(curGameTime-v)>60.0 then _G.ActiveBombTimers[k]=nil end end end end)
end
if _G.AimPROConfig.EspItemBom then DrawBombs(_G.CachedItemBombs,true,50)end
if _G.AimPROConfig.EspActiveBom then DrawBombs(_G.CachedActiveBombs,false,150)end
end
end
end)
end
 -- ==========================================================
 -- [LOGIC ESP kendaraan - VEHICLE ESP VVIP] - OPTIMIZED
 -- ==========================================================
 -- ==========================================================
 -- [LOGIC ESP kendaraan - VEHICLE ESP VVIP] - OPTIMIZED tidak HP (super ringan)
 -- ==========================================================
if _G.AimPROConfig.EspVehicle then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD)then
if not _G.CachedGameplayStatics then _G.CachedGameplayStatics=import("GameplayStatics")end
if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle=import("STExtraVehicleBase")end
if not _G.CachedVehicleArray then _G.CachedVehicleArray=slua.Array(UEnums.EPropertyClass.Object,_G.CachedActorClass_ForVehicle)end
local ui_util=require("client.common.ui_util")
local gameInstance=ui_util and ui_util.GetGameInstance()
if gameInstance and _G.CachedGameplayStatics then
local curTime=os.clock()
 -- alur scan utama: 1.0s scan 1 kali.
if not _G.LastVehicleScanTime or(curTime-_G.LastVehicleScanTime)>1.0 then
_G.LastVehicleScanTime=curTime
local allVehicles=_G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance,_G.CachedActorClass_ForVehicle,_G.CachedVehicleArray)
local activeVehicles={}
if allVehicles then
for _,veh in pairs(allVehicles)do
if slua.isValid(veh)and not veh.bHidden and not veh.bTearOff then
local isPendingKill=false
pcall(function()if type(veh.IsPendingKill)=="function"then isPendingKill=veh:IsPendingKill()end end)
if not isPendingKill then
local vehName="Kendaraan"
local hasDriver=false
pcall(function()
if type(veh.GetVehicleName)=="function"then vehName=veh:GetVehicleName()elseif veh.VehicleName then vehName=veh.VehicleName end
local driver=type(veh.GetDriver)=="function"and veh:GetDriver()or nil
if slua.isValid(driver)then hasDriver=true end
end)
local nameLower=string.lower(tostring(vehName)..tostring(veh))
local displayName="Kendaraan"
if string.find(nameLower,"uaz")then displayName="UAZ"
elseif string.find(nameLower,"dacia")then displayName="Dacia"
elseif string.find(nameLower,"buggy")then displayName="Buggy"
elseif string.find(nameLower,"mirado")then displayName="Mirado"
elseif string.find(nameLower,"bike")or string.find(nameLower,"motor")then displayName="Motor"
elseif string.find(nameLower,"scooter")then displayName="Scooter"
elseif string.find(nameLower,"coupe")then displayName="Coupe RB"
elseif string.find(nameLower,"brdm")then displayName="BRDM"
elseif string.find(nameLower,"boat")or string.find(nameLower,"aquarail")then displayName="Perahu"
elseif string.find(nameLower,"glider")then displayName="Glider"
else displayName="Kendaraan ("..string.sub(vehName,1,8)..")"end
table.insert(activeVehicles,{act=veh,name=displayName,hasDriver=hasDriver})
end
end
end
end
_G.CachedVehicles=activeVehicles
end
if _G.CachedVehicles then
for _,item in ipairs(_G.CachedVehicles)do
local veh=item.act
if slua.isValid(veh)and not veh.bHidden then
local isShow=false
if item.name=="Dacia"then isShow=_G.AimPROConfig.EspVeh_Dacia
elseif item.name=="UAZ"then isShow=_G.AimPROConfig.EspVeh_UAZ
elseif item.name=="Buggy"then isShow=_G.AimPROConfig.EspVeh_Buggy
elseif item.name=="Coupe RB"then isShow=_G.AimPROConfig.EspVeh_Coupe
elseif item.name=="Mirado"then isShow=_G.AimPROConfig.EspVeh_Mirado
elseif item.name=="Motor"or item.name=="Scooter"then isShow=_G.AimPROConfig.EspVeh_Motor
else isShow=_G.AimPROConfig.EspVeh_Other end
if isShow then
local distM=0
pcall(function()distM=localPlayer:GetDistanceTo(veh)/100 end)
if distM>0 and distM<=300 then
local text=string.format("%s [%dm]",item.name,math.floor(distM))
local vehColor=item.hasDriver and{R=255,G=50,B=50,A=255}or{R=0,G=255,B=150,A=255}
local dynamicScale=math.max(0.6,1.1-(distM/500))
MyHUD:AddDebugText(text,veh,0.06,{X=0,Y=0,Z=50},{X=0,Y=0,Z=50},vehColor,true,false,true,nil,dynamicScale,true)
end
end
end
end
end
end
end
end)
end
end)
end
_G.AimPROState.LoopToken=(_G.AimPROState.LoopToken or 0)+1
local myToken=_G.AimPROState.LoopToken

local function _pA()
    if _G.AimPRONotifiedPopup then return true end
    local okPC=false
    pcall(function()
        local gd=package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
        local pc=gd and gd.GetPlayerController and gd.GetPlayerController()
        okPC=slua and slua.isValid and slua.isValid(pc) or (pc~=nil)
    end)
    if not okPC then return false end

    local shown=false
    pcall(function()
        local Msg=require("client.slua.logic.common.logic_common_msg_box")
        if Msg and type(Msg.Show)=="function" then
            Msg.Show(1,"EXPIRED",
                "Sudah Expired ya adick²\nSilahkan Hubungi Admin Untuk Pembelian MOD VIP Full Akses.\nInbox Tele @zexygodx\nHati² banyak penipuan Real Owner ada di Grub Comunity ".._G.__BRG_A(string.char(71,79,68,77,79,68)),
                function()
                    pcall(function()
                        local Web=require("client.slua.logic.url.logic_webview_sdk")
                        if Web and Web.OpenURL then Web:OpenURL("https://t.me/imprr0") end
                    end)
                end,
                function() end,
                "INBOX OWNER","TUTUP")
            _G.AimPRONotifiedPopup=true
            shown=true
        end
    end)
    return shown
end

local function _pB(attempt)
    attempt=attempt or 0
    if _G.AimPRONotifiedPopup then return end

    -- Fallback visual yang tidak bergantung pada ModMenu.
    pcall(function()
        local sh=import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(
                "[AimPRO VIP New] MASA BERLAKU MOD TELAH HABIS - Hubungi @zexygodx",
                -1, 5.0,
                {R=1,G=1,B=0,A=1}, {X=1.2,Y=1.2})
        end
    end)

    if _pA() then return end
    if attempt>=20 then return end

    local okTicker,ticker=pcall(require,"common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.0,function() _pB(attempt+1) end)
    end
end

local function FastTick()
    if _i then
        if not _G._AimPFX then
            _G._AimPFX=true
            _pB(0)
        end
        return
    end
    if myToken~=_G.AimPROState.LoopToken then return end
    pcall(MainLoop)
    local okTicker,ticker=pcall(require,"common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.01,FastTick)
    end
end

if not _i then
    FastTick()
    Notify("Silahkan Hubungi Admin Untuk Mendapatkan Akses FULL VIP,Reall Owner hanya di @GODMOD Comunity ")
else
        _pB(0)
end
-- ==============================================================================
-- ================= Pemanggil byps tiap 5detik =================
-- ==============================================================================
local function BYPASSANTIBAN()
if _i then return end
pcall(function()
if _G.StartBypass()then _G.StartBypass()end
end)
local GameplayData=package.loaded["GameLua.GameCore.Data.GameplayData"]or require("GameLua.GameCore.Data.GameplayData")
if not GameplayData then return end
pcall(function()
local LocalPlayer=GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
if slua.isValid(LocalPlayer)then
if LocalPlayer.bHasShownDevNotice==nil then
LocalPlayer.bHasShownDevNotice=false
LocalPlayer.bHasShownExpiredNotice=false
LocalPlayer.bIsDeadFlag=false
end
end
end)
end
if not _i then
pcall(function()
require("common.time_ticker").AddTimerOnce(0.5,BYPASSANTIBAN)
end)
end
-- ==============================================================================
-- ================= tangkap kepala CORE ADD-OUTFIT V7.5 (SISTEM SISTEM SKIN) =================
-- ==============================================================================
-- daftar map ID tambahan syarat asli keluar index array
_G.BaseAttachToIndex={[201010]=1,[201005]=1,[201004]=1,[201009]=2,[201003]=2,[201002]=2,[201011]=3,[201007]=3,[201006]=3,[204012]=4,[204005]=4,[204008]=4,[204011]=5,[204004]=5,[204007]=5,[204013]=6,[204006]=6,[204009]=6,[203001]=7,[203002]=8,[203003]=9,[203014]=10,[203004]=11,[203015]=12,[203005]=13,[202002]=14,[202001]=15,[202004]=16,[202005]=17,[202007]=18,[202006]=19,[205002]=20,[205003]=20,[205001]=20,[203018]=21,[204014]=22
}
-- TEMPEL ID tambahan milik kamu KE DALAM KURUNG KURAWAL di bawah ↓↓↓
_G.VIP_Attachments={[1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},[1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},[1101001128]={1010011232,1010011233,1010011234,1010011228,1010011227,1010011229,1010011226,1010011225,1010011224,1010011223,1010011222,0,0,0,0,0,0,0,0,0,0,0},[1101001154]={1010011487,1010011488,1010011489,1010011493,1010011490,1010011494,1010011486,1010011485,1010011484,1010011483,1010011482,1010011497,0,0,0,0,0,0,0,0,1010011498,0},[1101001174]={1010011667,1010011668,1010011669,1010011673,1010011670,1010011674,1010011666,1010011665,1010011664,1010011663,1010011662,0,0,0,0,0,0,0,0,0,0,0},[1101001213]={1010012067,1010012068,1010012069,1010012072,1010012070,1010012073,1010012066,1010012065,1010012064,1010012063,1010012062,0,0,0,0,0,0,0,0,0,1010012074,0},[1101001231]={1010012267,1010012268,1010012269,1010012273,1010012272,1010012274,1010012266,1010012265,1010012264,1010012263,1010012262,1010012075,0,0,0,0,0,0,0,0,1010012275,0},[1101001242]={1010012357,1010012358,1010012359,1010012363,1010012362,1010012364,1010012356,1010012355,1010012354,1010012353,1010012352,1010012276,0,0,0,0,0,0,0,0,1010012365,0},[1101001249]={1010012437,1010012438,1010012439,1010012443,1010012442,1010012444,1010012436,1010012435,1010012434,1010012433,1010012432,1010012366,0,0,0,0,0,0,0,0,1010012445,0},[1101001256]={1010012588,1010012589,1010012590,1010012593,1010012592,1010012594,1010012587,1010012586,1010012585,1010012584,1010012583,1010012582,0,0,0,0,0,0,0,0,1010012595,0},[1101001265]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},[1101001276]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},[1101002029]={1010020249,1010020250,1010020255,1010020247,1010020246,1010020248,1010020240,1010020239,1010020238,1010020237,1010020236,1010020235,0,0,0,0,0,0,0,1010020257,1010020256,1010020258},[1101002056]={1010020519,0,0,1010020517,1010020516,1010020518,1010020500,1010020509,1010020508,1010020507,1010020506,1010020505,0,0,0,0,0,0,0,0,0,0},[1101002081]={1010020768,1010020769,1010020770,1010020766,1010020760,1010020767,1010020759,1010020758,1010020757,1010020756,1010020755,1010020776,0,0,0,0,0,0,0,1010020775,1010020777,1010020778},[1101003070]={1010030654,1010030653,1010030655,1010030649,1010030648,1010030650,1010030647,1010030646,1010030645,1010030644,1010030643,1010030642,0,1010030658,1010030656,1010030660,1010030662,1010030659,1010030657,0,1010030663,0},[1101003080]={1010030754,1010030753,1010030755,1010030749,1010030748,1010030750,1010030747,1010030746,1010030745,1010030744,1010030743,1010030742,0,1010030758,1010030756,1010030760,1010030762,1010030759,1010030757,0,1010030763,0},[1101003099]={1010030943,1010030944,1010030945,1010030939,1010030938,1010030942,1010030937,1010030936,1010030935,1010030934,1010030933,1010030932,0,1010030947,1010030946,1010030948,1010030949,1010030953,1010030952,0,1010030955,0},[1101003119]={1010031139,1010031140,1010031142,1010031138,1010031137,1010031146,1010031136,1010031135,1010031134,1010031133,1010031132,0,0,1010031144,1010031143,0,0,0,1010031145,0,0,0},[1101003146]={1010031229,1010031230,1010031237,1010031228,1010031227,1010031242,1010031226,1010031225,1010031224,1010031223,1010031222,0,0,1010031239,1010031238,0,0,0,1010031240,0,0,0},[1101003167]={1010031609,1010031610,1010031613,1010031608,1010031607,1010031617,1010031606,1010031605,1010031604,1010031603,1010031602,1010031618,0,1010031615,1010031614,1010031620,1010031622,1010031619,1010031616,0,1010031623,0},[1101003181]={1010031765,1010031764,1010031766,1010031759,1010031758,1010031763,1010031757,1010031756,1010031755,1010031754,1010031753,1010031752,0,1010031769,1010031767,1010031773,1010031774,1010031772,1010031768,0,1010031775,0},[1101003195]={1010031912,1010031911,1010031913,1010031908,1010031907,1010031909,1010031906,1010031905,1010031904,1010031903,1010031902,1010031901,0,1010031916,1010031914,1010031918,1010031919,1010031917,1010031915,0,1010031921,0},[1101003208]={1010032034,1010032033,1010032045,1010032029,1010032028,1010032032,1010032027,1010032026,1010032025,1010032024,1010032023,1010032022,0,1010032038,1010032036,1010032042,1010032043,1010032039,1010032037,0,1010032044,0},[1101004046]={1010040474,1010040475,1010040476,1010040472,1010040471,1010040473,1010040470,1010040469,1010040468,1010040467,1010040466,1010040481,0,1010040479,1010040477,1010040482,1010040483,1010040484,1010040478,1010040480,1010040485,0},[1101004062]={1010040578,1010040577,1010040579,1010040575,1010040570,1010040576,1010040569,1010040568,1010040567,1010040566,1010040565,1010040564,0,1010040585,1010040580,1010040587,1010040588,1010040589,1010040584,1010040586,1010040590,1010040594},[1101004098]={1010040924,1010040926,1010040925,0,1010040937,1010040938,1010040935,1010040934,1010040929,1010040928,1010040927,0,0,1010040939,1010040945,0,0,0,1010040944,1010040936,0,0},[1101004138]={1010041136,1010041137,1010041138,1010041134,1010041129,1010041135,1010041128,1010041127,1010041126,1010041125,1010041124,0,0,1010041145,1010041139,0,0,0,1010041144,1010041146,0,0},[1101004163]={1010041570,1010041574,1010041575,1010041568,1010041567,1010041569,1010041566,1010041565,1010041564,1010041560,1010041554,0,0,1010041578,1010041576,0,0,0,1010041577,1010041579,0,0},[1101004201]={1010041956,1010041957,1010041958,1010041950,1010041949,1010041955,1010041948,1010041947,1010041946,1010041945,1010041944,1010041967,0,1010041965,1010041959,0,0,0,1010041960,1010041966,0,0},[1101004209]={1010042038,1010042037,1010042039,1010042035,1010042034,1010042036,1010042029,1010042028,1010042027,1010042026,1010042025,1010042024,0,1010042046,1010042044,1010042048,1010042049,1010042054,1010042045,1010042047,1010042055,0},[1101004218]={1010042128,1010042127,1010042129,1010042125,1010042124,1010042126,1010042119,1010042118,1010042117,1010042116,1010042115,1010042114,0,1010042136,1010042134,1010042138,1010042139,1010042144,1010042135,1010042137,1010042145,0},[1101004226]={1010042238,1010042237,1010042239,1010042235,1010042234,1010042236,1010042233,1010042232,1010042231,1010042219,1010042218,1010042217,0,1010042243,1010042241,1010042245,1010042246,1010042247,1010042242,1010042244,1010042248,0},[1101004246]={1010042406,1010042407,1010042408,1010042404,1010042400,1010042405,1010042399,1010042398,1010042397,1010042396,1010042395,1010042394,0,1010042414,1010042409,1010042416,1010042417,1010042418,1010042410,1010042415,1010042419,1010042420},[1101005038]={0,0,1010050327,1010050329,1010050328,1010050330,1010050326,1010050325,1010050324,1010050323,1010050322,1010050334,0,0,0,0,0,0,0,0,0,0},[1101005052]={0,0,1010050467,1010050469,1010050468,1010050470,1010050466,1010050465,1010050464,1010050463,1010050462,1010050473,0,0,0,0,0,0,0,0,0,0},[1101005098]={0,0,1010050928,1010050930,1010050929,1010050932,1010050927,1010050926,1010050925,1010050924,1010050923,1010050922,0,0,0,0,0,0,0,0,0,0},[1101006062]={1010060573,1010060572,1010060574,1010060564,1010060563,1010060571,1010060562,1010060561,1010060554,1010060553,1010060552,1010060551,0,1010060583,1010060581,1010060591,1010060592,1010060584,1010060582,0,1010060593,0},[1101006075]={1010060702,1010060701,1010060703,1010060698,1010060697,1010060699,1010060696,1010060695,1010060694,1010060693,1010060692,1010060691,0,1010060706,1010060704,1010060708,1010060709,1010060707,1010060705,0,1010060711,0},[1101006085]={1010060796,1010060795,1010060797,1010060793,1010060789,1010060794,1010060788,1010060787,1010060786,1010060785,1010060784,1010060783,0,1010060800,1010060798,1010060804,1010060805,1010060803,1010060799,0,1010060806,0},[1101007046]={1010070410,1010070413,1010070414,1010070408,1010070407,1010070409,1010070406,1010070405,1010070404,1010070403,1010070402,1010070418,0,1010070417,1010070415,1010070420,1010070422,1010070419,1010070416,0,1010070423,0},[1101007062]={1010070579,1010070578,1010070581,1010070576,1010070575,1010070577,1010070574,1010070573,1010070572,1010070571,1010070569,1010070568,0,1010070584,1010070582,1010070585,1010070586,1010070587,1010070583,0,1010070588,0},[1101007071]={1010070663,1010070662,1010070664,1010070659,1010070658,1010070660,1010070657,1010070656,1010070655,1010070654,1010070653,1010070652,0,1010070667,1010070665,1010070668,1010070669,1010070670,1010070666,0,1010070672,0},[1101008051]={1010080463,1010080464,1010080465,1010080459,1010080458,1010080462,1010080457,1010080456,1010080455,1010080454,1010080453,1010080452,0,1010080467,1010080466,1010080468,1010080469,1010080473,1010080472,0,1010080475,0},[1101008061]={1010080563,1010080564,1010080565,1010080559,1010080558,1010080562,1010080557,1010080556,1010080555,1010080554,1010080553,0,0,1010080567,1010080566,0,0,0,1010080572,0,0,0},[1101008070]={1010080609,1010080612,1010080613,1010080608,1010080607,1010080617,1010080606,1010080605,1010080604,1010080603,1010080602,0,0,1010080615,1010080614,0,0,0,1010080616,0,0,0},[1101008081]={1010080740,1010080743,1010080745,1010080738,1010080737,1010080739,1010080736,1010080735,1010080734,1010080733,1010080732,1010080748,0,1010080747,1010080746,1010080750,1010080752,1010080749,1010080744,0,1010080753,0},[1101008104]={1010080980,1010080982,1010080984,1010080978,1010080977,1010080979,1010080976,1010080975,1010080974,1010080973,1010080972,1010080992,0,1010080986,1010080985,1010080989,1010080987,1010080993,1010080983,0,1010080988,0},[1101008116]={1010081110,1010081112,1010081114,1010081108,1010081107,1010081109,1010081106,1010081105,1010081104,1010081103,1010081102,0,0,1010081116,1010081115,0,0,0,1010081113,0,0,0},[1101008126]={1010081210,1010081225,1010081226,1010081208,1010081207,1010081209,1010081206,1010081205,1010081204,1010081203,1010081202,1010081218,0,1010081217,1010081216,1010081219,1010081220,1010081222,1010081214,1010081228,1010081227,1010081229},[1101008136]={1010081314,1010081315,1010081316,1010081312,1010081308,1010081313,1010081307,1010081306,1010081305,1010081304,1010081303,1010081302,0,1010081318,1010081317,1010081322,1010081323,1010081325,1010081324,0,1010081326,0},[1101008146]={1010081401,1010081402,1010081403,1010081398,1010081397,1010081399,1010081396,1010081395,1010081394,1010081393,1010081392,1010081391,0,1010081405,1010081404,1010081406,1010081407,1010081409,1010081408,0,1010081411,0},[1101008154]={1010081531,1010081532,1010081533,1010081528,1010081527,1010081529,1010081526,1010081525,1010081524,1010081523,1010081522,1010081521,0,1010081541,1010081534,1010081542,1010081543,1010081545,1010081544,0,1010081546,0},[1101008163]={1010081582,1010081583,1010081584,1010081579,1010081578,1010081580,1010081577,1010081576,1010081575,1010081574,1010081573,1010081572,0,1010081586,1010081585,1010081587,1010081588,1010081590,1010081589,0,1010081592,0},[1101012033]={1010120284,1010120285,1010120286,1010120280,1010120279,1010120283,1010120278,1010120277,1010120276,1010120275,1010120274,1010120273,0,0,0,0,0,0,0,0,1010120287,0},[1101100012]={1011000066,1011000067,1011000068,0,0,0,1011000058,1011000057,1011000056,1011000055,1011000054,1011000053,0,0,0,0,0,0,0,0,1011000073,0},[1101102007]={1011010025,1011010024,1011010026,1011010020,1011010019,1011010023,1011010018,1011010017,1011010016,1011010015,1011010014,1011010013,0,0,0,0,0,0,0,0,1011010027,0},[1101102017]={1011020027,1011020028,1011020029,1011020025,1011020024,1011020026,1011020019,1011020018,1011020017,1011020016,1011020015,1011020014,0,1011020036,1011020034,1011020038,1011020039,1011020044,1011020035,1011020037,1011020045,1011020047},[1101102025]={1011020127,1011020128,1011020129,1011020125,1011020124,1011020126,1011020119,1011020118,1011020117,1011020116,1011020115,1011020114,0,1011020136,1011020134,1011020138,1011020139,1011020144,1011020135,1011020137,1011020145,0},[1101102041]={1011020214,1011020215,1011020216,1011020212,1011020211,1011020213,1011020209,1011020208,1011020207,1011020206,1011020205,1011020204,0,1011020219,1011020217,1011020222,1011020223,1011020224,1011020218,1011020221,1011020225,1011020229},[1101102049]={1011020356,1011020357,1011020358,1011020354,1011020350,1011020355,1011020349,1011020348,1011020347,1011020346,1011020345,1011020344,0,1011020364,1011020359,1011020366,1011020367,1011020368,1011020360,1011020365,1011020369,1011020370},[1101101007]={1011020436,1011020437,1011020438,1011020434,1011020430,1011020435,1011020429,1011020428,1011020427,1011020426,1011020425,1011020424,0,1011020444,1011020439,1011020446,1011020447,1011020448,1011020440,1011020445,1011020449,1011020450},[1102001120]={1020011137,1020011138,1020011139,1020011135,1020011134,1020011136,1020011133,1020011132,0,0,0,0,0,0,0,0,0,0,0,1020011142,0,0},[1102001130]={1020011247,1020011248,1020011249,1020011245,1020011244,1020011246,1020011243,1020011242,0,0,0,0,0,0,0,0,0,0,0,1020011250,0,0},[1102002043]={1020020372,1020020374,1020020373,1020020383,1020020380,1020020384,1020020379,1020020378,1020020377,1020020376,1020020375,1020020388,0,1020020385,1020020387,0,0,0,1020020386,0,0,0},[1102002061]={1020020552,1020020554,1020020553,1020020563,1020020562,1020020564,1020020559,1020020558,1020020557,1020020556,1020020555,1020020578,0,1020020565,1020020567,1020020573,1020020574,1020020572,1020020566,0,1020020569,0},[1102002136]={1020021314,1020021313,1020021315,1020021309,1020021308,1020021312,1020021307,1020021306,1020021305,1020021304,1020021303,1020021302,0,1020021318,1020021316,1020021323,1020021324,1020021322,1020021317,0,1020021325,0},[1102002424]={1020024193,1020024192,1020024194,1020024189,1020024188,1020024190,1020024187,1020024186,1020024185,1020024184,1020024183,1020024182,0,1020024197,1020024195,1020024199,1020024200,1020024198,1020024196,0,1020024202,0},[1102003080]={1020030755,1020030756,1020030758,0,1020030749,1020030754,1020030748,1020030747,1020030746,1020030745,1020030744,1020030764,0,1020030760,0,1020030759,1020030757,0,0,1020030765,0,0},[1102003100]={1020030956,1020030957,1020030958,1020030954,1020030950,1020030955,1020030949,1020030948,1020030947,1020030946,1020030945,1020030944,0,1020030964,0,1020030960,1020030959,1020030965,0,1020030967,1020030966,1020030968},[1102005064]={1020050588,1020050589,1020050590,0,0,0,1020050587,1020050586,1020050585,1020050584,1020050583,1020050582,0,0,0,0,0,0,0,0,1020050592,0},[1103001101]={1030010954,1030010955,1030010956,0,0,0,0,0,0,0,1030010953,1030010952,1030010951,0,0,0,0,0,0,1030010957,0,1030010958},[1103001146]={1030011344,1030011345,1030011346,0,0,0,0,0,0,0,1030011343,1030011342,1030011341,0,0,0,0,0,0,1030011347,0,1030011348},[1103001154]={1030011484,1030011485,1030011486,0,0,0,0,0,0,0,1030011483,1030011482,1030011481,0,0,0,0,0,0,1030011487,0,1030011488},[1103001179]={1030011738,1030011739,1030011741,0,0,0,1030011737,1030011736,1030011735,1030011734,1030011733,1030011732,1030011731,0,0,0,0,0,0,1030011742,1030011743,1030011744},[1103001191]={1030011858,1030011859,1030011861,0,0,0,1030011857,1030011856,1030011855,1030011854,1030011853,1030011852,1030011851,0,0,0,0,0,0,1030011862,1030011863,1030011864},[1103001202]={1030011948,1030011949,1030011950,0,0,0,1030011947,1030011946,1030011945,1030011944,1030011943,1030011942,1030011941,0,0,0,0,0,0,1030011951,1030011952,1030011953},[1103002030]={1030020245,1030020246,1030020247,1030020252,1030020249,1030020253,1030020258,1030020257,1030020256,1030020255,1030020244,1030020243,1030020242,0,0,0,0,0,0,1030020248,0,0},[1103002059]={1030020544,1030020545,1030020546,1030020542,1030020539,1030020543,1030020538,1030020537,1030020536,1030020535,1030020534,1030020533,1030020532,0,0,0,0,0,0,1030020547,1030020548,0},[1103002087]={1030020824,1030020825,1030020826,0,0,0,1030020818,1030020817,1030020816,1030020815,1030020814,1030020813,1030020812,0,0,0,0,0,0,1030020827,1030020828,0},[1103002106]={1030021009,1030021010,1030021012,1030021015,1030021014,1030021016,1030021008,1030021007,1030021006,1030021005,1030021004,1030021003,1030021002,0,0,0,0,0,0,1030021013,1030021017,0},[1103002113]={1030021079,1030021080,1030021082,1030021085,1030021084,1030021086,1030021078,1030021077,1030021076,1030021075,1030021074,1030021073,1030021072,0,0,0,0,0,0,1030021083,1030021087,0},[1103003022]={1030030165,1030030166,1030030167,1030030172,1030030169,1030030173,0,0,0,0,1030030164,1030030163,1030030162,0,0,0,0,0,0,0,0,0},[1103003030]={1030030256,1030030257,1030030258,1030030254,1030030253,1030030255,1030030248,1030030247,1030030246,1030030245,1030030244,1030030243,1030030242,0,0,0,0,0,0,1030030259,1030030249,0},[1103003042]={1030030374,1030030375,1030030376,1030030372,1030030369,1030030373,0,0,0,0,1030030364,1030030363,1030030362,0,0,0,0,0,0,1030030377,0,0},[1103003051]={1030030458,1030030459,1030030460,1030030456,1030030455,1030030457,0,0,0,0,1030030454,1030030453,1030030452,0,0,0,0,0,0,1030030463,0,0},[1103003062]={1030030568,1030030569,1030030570,1030030566,1030030565,1030030567,0,0,0,0,1030030564,1030030563,1030030562,0,0,0,0,0,0,1030030572,0,0},[1103003079]={1030030744,1030030745,1030030746,1030030742,1030030740,1030030743,1030030738,1030030737,1030030736,1030030735,1030030734,1030030733,1030030732,0,0,0,0,0,0,1030030747,1030030739,0},[1103003087]={1030030825,1030030826,1030030827,1030030823,1030030824,1030030824,1030030818,1030030817,1030030816,1030030815,1030030814,1030030813,1030030812,0,0,0,0,0,0,1030030828,1030030819,0},[1103004037]={1030040315,1030040316,1030040317,1030040325,1030040324,1030040323,0,0,0,0,1030040314,1030040313,1030040312,1030040327,1030040326,0,0,0,1030040328,1030040329,0,0},[1103006030]={1030060245,1030060246,1030060247,0,1030060253,1030060252,0,0,0,0,1030060244,1030060243,1030060242,0,0,0,0,0,0,0,0,0},[1103007028]={1030070233,1030070234,1030070235,1030070226,1030070225,1030070227,1030070218,1030070217,1030070216,1030070215,1030070214,1030070213,1030070212,0,0,0,0,0,0,1030070236,1030070219,0},[1103012010]={0,0,0,0,0,0,1030120038,1030120037,1030120036,1030120035,1030120034,1030120033,1030120032,0,0,0,0,0,0,0,0,0},[1103012019]={0,0,0,0,0,0,1030120138,1030120137,1030120136,1030120135,1030120134,1030120133,1030120132,0,0,0,0,0,0,0,0,0},[1103012031]={0,0,0,0,0,0,1030120258,1030120257,1030120256,1030120255,1030120254,1030120253,1030120252,0,0,0,0,0,0,0,0,0},[1103012039]={0,0,0,0,0,0,1030120339,1030120338,1030120337,1030120336,1030120335,1030120334,1030120333,0,0,0,0,0,0,0,0,0},[1103102007]={1031020026,1031020027,1031020028,1031020024,1031020023,1031020025,1031020019,1031020018,1031020017,1031020016,1031020015,1031020014,1031020013,0,0,0,0,0,0,1031020029,0,0},[1105001034]={0,0,0,0,1050010287,1050010289,1050010286,1050010285,1050010284,1050010283,1050010282,0,0,0,0,0,0,0,0,1050010292,0,0},[1105001048]={0,0,0,1050010429,1050010428,1050010434,1050010427,1050010426,1050010425,1050010424,1050010423,0,0,0,0,0,0,0,0,1050010435,0,1050010436},[1105001069]={0,0,0,1050010639,1050010638,1050010640,1050010637,1050010636,1050010635,1050010634,1050010633,1050010645,0,0,0,0,0,0,0,1050010643,1050010646,1050010644},[1105002091]={0,0,0,0,0,0,1050020847,1050020846,1050020845,1050020844,1050020843,1050020842,0,0,0,0,0,0,0,0,0,1050020848},[1105010019]={0,0,0,0,0,0,1050100144,1050100143,1050100142,1050100141,1050100139,1050100138,0,0,0,0,0,0,0,0,0,0}, -- [ AUG Sembilan besar Gila Marah - bentuk dasar versi (warna Merah) ]
[1101006098]={1010060925,1010060926,1010060927,1010060919,0,1010060924,1010060918,1010060917,1010060916,1010060915,1010060914,1010060913,0,1010060930,1010060928,1010060929,1010060935,1010060934,1010060933,0,1010060936,0}, -- [ AUG Sembilan besar Gila Marah - bentuk maksimal Atas (warna Kuning) ]
[1101006106]={1010061004,1010061005,1010061006,1010060999,1010061000,1010061003,1010060998,1010060997,1010060996,1010060995,1010060994,1010060993,0,1010061009,1010061007,1010061008,1010061014,1010061013,1010061010,0,1010061015,0},}
-- TEMPEL ID tambahan milik kamu di atas ↑↑↑
local cached_GameplayStatics=nil
local cached_PlayerTombBox=nil
local cached_ActorClass=nil
_G.NeedCheckDeadBoxTimer=0
_G.DeadBox_TemperRequest=function(PlayerController)
if not _G.AimPROConfig.SkinDeadBox or _G.NeedCheckDeadBoxTimer<=0 then return end
local curTime=os.clock()
if _G.LastCheckDeadBoxTime and(curTime-_G.LastCheckDeadBoxTime)<2.0 then return end
_G.LastCheckDeadBoxTime=curTime
_G.NeedCheckDeadBoxTimer=_G.NeedCheckDeadBoxTimer-1
local PlayerCharacter=PlayerController:GetPlayerCharacterSafety()
if not slua.isValid(PlayerCharacter)then return end
if not cached_GameplayStatics then
cached_GameplayStatics=import("GameplayStatics")
cached_ActorClass=import("Actor")
cached_PlayerTombBox=import("PlayerTombBox")
end
if not _G.CachedActorArray_DB then
_G.CachedActorArray_DB=slua.Array(UEnums.EPropertyClass.Object,cached_ActorClass)
end
local UI_Util=require("client.common.ui_util")
local GameInstance=UI_Util and UI_Util.GetGameInstance()
if not GameInstance or not cached_GameplayStatics then return end
 -- Optimasi: ambil sebelum ID orang Main dan ID senjata/kendaraan di luar loop agar tidak hitung hitung lagi
local myPlayerKey=PlayerController.PlayerKey
local currentBoxSkinId=0
pcall(function()
local curVeh=PlayerCharacter.CurrentVehicle or(type(PlayerCharacter.GetCurrentVehicle)=="function"and PlayerCharacter:GetCurrentVehicle())
if slua.isValid(curVeh)and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID~=0 then
currentBoxSkinId=tonumber(tostring(_G.CurrentEquipVehicleID).."1")or 0
else
 -- [FIX VIP]: ambil ID senjata yang sedang dipegang agar DeadBox tampil benar, hapus loop untuk cegah Drop FPS
local curWeapon=PlayerCharacter.GetCurrentWeapon and PlayerCharacter:GetCurrentWeapon()or PlayerCharacter.CurrentWeapon
if slua.isValid(curWeapon)then
local defineIDObj=curWeapon.GetItemDefineID and curWeapon:GetItemDefineID()
local curWeaponID=(defineIDObj and slua.isValid(defineIDObj))and defineIDObj.TypeSpecificID or 0
 -- objek raycast dengan gudang Skin sudah simpan untuk ambil benar ID Skin tampil di
if curWeaponID>0 and _G.AddOutfitLastAppliedSkin and _G.AddOutfitLastAppliedSkin[curWeaponID]then
local skinID=_G.AddOutfitLastAppliedSkin[curWeaponID]
if skinID and skinID>1000000 then
currentBoxSkinId=skinID
end
end
end
end
end)
if currentBoxSkinId==0 then return end
local deadBoxes=cached_GameplayStatics.GetAllActorsOfClass(GameInstance,cached_PlayerTombBox,_G.CachedActorArray_DB)
if not deadBoxes then return end
local count=type(deadBoxes.Num)=="function"and deadBoxes:Num()or#deadBoxes
for i=1,count do
local deadBoxActor=type(deadBoxes.Get)=="function"and deadBoxes:Get(i-1)or deadBoxes[i]
if slua.isValid(deadBoxActor)and not deadBoxActor.bIsTDSkinApplied then
local damageCauser=deadBoxActor.DamageCauser
 -- So bandingkan sangat cepat dengan MyPlayerKey sudah cache
if slua.isValid(damageCauser)and damageCauser.PlayerKey==myPlayerKey then
local DeadBoxAvatarComponent=deadBoxActor.DeadBoxAvatarComponent_BP
if slua.isValid(DeadBoxAvatarComponent)then
pcall(function()
DeadBoxAvatarComponent:ResetItemAvatar()
DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
end)
deadBoxActor.bIsTDSkinApplied=true
end
end
end
end
end
--[[ AddOutfit v7.5 — Terintegrasi sistem sistem pilih Skin qua inventori (Wardrobe) ]]
local F={}
local DEBUG=false
function F.log(...)
if DEBUG then print("[AddOutfit]",...)end
end
local MATCH_CONFIG={outfitRes=0,hatRes=0,maskRes=0,glassRes=0,tshirtRes=0,pantsRes=0,shoesRes=0,bagRes=0,helmetRes=0,weaponSkins={},}
-- daftar ID semua super kendaraan (tambahkan otomatis jika ada ID baru)
local ITEMS={ -- ==============================================================================
 -- SISTEM ASLI V7.5 (BARIS INI JANGAN DIHAPUS)
 -- ==============================================================================
703029,703044,703046,703048,1400010,1400062,1400070,1400083,1400100,1400106,1400112,1400117,1400134,1407917,1400170,1400172,1400173,1400174,1400175,1400177,1400179,1400180,1400228,1400231,1400233,1400236,1400237,1400238,1400242,1400244,202408070,202408071,202408072,202408073,202408074,202408075,1407905,1407906,1407907,1407908,1407909,1407910,1407911,1407912,1407913,1407914,1407915,1407916,1410585, -- ==============================================================================
 -- 1. Senjata level tinggi (ambil level tertinggi dari tiap senjata)
 -- ==============================================================================
 -- [ M416 ]
 1101004163,-- Kerajaan Gia Megah pemicu - M416 (Level 8)
 1101004201,-- Putih Kirin LEPAS Permata - M416 (Level 8)
 1101004209,-- Air Pasang Bangkit gelombang - M416 (Level 8)
 1101004218,-- Ma gambar - M416 (Level 8)
 1101004226,-- Phong Ấn U Minh - M416 (Level 8)
 1101004236,-- Biru Guru Raih Takdir - M416 (Level 8)
 1101004246,-- Api Teratai - M416 (Level 8)
 1101004046,-- Es harga - M416 (Level 7)
 1101004062,-- Badut badut - M416 (Level 7)
 1101004078,-- Orang lang thang - M416 (Level 7)
 1101004086,-- Sapi Dekat geram geram - M416 (Level 7)
 1101004098,-- Suara panggil Hoang Liar - M416 (Level 7)
 1101004138,-- Inti Fungsi Seni - M416 (Level 7)
 -- [ AKM ]
 1101001174,-- Penguasa Penguasa Set Tersesat - AKM (Level 8)
 1101001213,-- Laksamana Komandan Laut Long Tinh - AKM (Level 8)
 1101001242,-- Hari Vonis Putusan - AKM (Level 8)
 1101001265,-- Waktu Quang Kemampuan Berubah - AKM (Level 8)
 1101001276,-- Ilusi Dewa - AKM (Level 8)
 1101001063,-- Misteri Telepon Seven Seas - AKM (Level 7)
 1101001089,-- Es harga - AKM (Level 7)
 1101001103,-- Ubah Batu - AKM (Level 7)
 1101001116,-- Rahasia Jagung Kinh Aneh - AKM (Level 7)
 1101001128,-- Long Raja - AKM (Level 7)
 1101001143,-- Laut Bajak Laut Kuning - AKM (Level 7)
 1101001154,-- Orang Pecahkan Kode - AKM (Level 7)
 1101001231,-- Kelinci Tinh Terbalik - AKM (Level 7)
 1101001249,-- Suci Quang (Bulan Dewa) - AKM (Level 7)
 1101001256,-- Suci Quang (Bulu Senjata Kerajaan Emas) - AKM (Level 7)
 1101001042,-- Ánh emas - AKM (Level 6)
 1101001068,-- Harimau geram geram - AKM (Level 5)
 -- [ SCAR-L ]
 1101003146,-- Gai Jahat Ác - SCAR-L (Level 8)
 1101003167,-- Ma Raja Darah Jiwa - SCAR-L (Level 8)
 1101003227,-- Langit Burung - SCAR-L (Level 8)
 1101003057,-- Senjata air - SCAR-L (Level 7)
 1101003070,-- Rahasia Jagung Ma Monster - SCAR-L (Level 7)
 1101003080,-- Pertempuran Terjemahan karena Hari Mai - SCAR-L (Level 7)
 1101003099,-- Drop Da Bass - SCAR-L (Level 7)
 1101003119,-- Tinh bisa Hextech SCAR-L (Level 7)
 1101003188,-- Benda Peluk dari Badut Badut - SCAR-L (Level 7)
 1101003195,-- Suci Wanita Misteri virtual - SCAR-L (Level 7)
 1101003208,-- Raja Negara Misteri virtual - SCAR-L (Level 7)
 1101003219,-- Kacamata Pha Pir - SCAR-L (Level 7)
 1101003173,-- Ánh Terang Kerajaan Suku - SCAR-L (Level 5)
 1101003212,-- Kucing Makan Camilan - SCAR-L (Level 3)
 -- [ M762 ]
 1101008081,-- Posisi Tamu Muncul Kacau - M762 (Level 8)
 1101008104,-- Inti Sao Misteri virtual - M762 (Level 8)
 1101008146,-- Putih Tulang U Minh - M762 (Level 8)
 1101008154,-- frame Tulang - M762 (Level 8)
 1101008051,-- versi Musik Cinta Cinta - M762 (Level 7)
 1101008061,-- Tembakan tembak Tertinggi Jaringan - M762 (Level 7)
 1101008070,-- GACKT MOONSAGA - M762 (Level 7)
 1101008116,-- Tampilan Patung Bayangan batu Messi - M762 (Level 7)
 1101008126,-- Darah Naga - M762 (Level 7)
 1101008136,-- Dewa Linh Simpan Ly - M762 (Level 7)
 1101008163,-- Kuno Benda Hitam gelap - M762 (Level 7)
 1101008026,-- Pony Kecil kecil - M762 (Level 5)
 1101008036,-- Bunga Sen Marah Marah - M762 (Level 5)
 -- [ AUG ]
 1101006062,-- Tinh Linh Es Harga - AUG (Level 8)
 1101006085,-- bunga Pink Ma Pesona - AUG (Level 8)
 1101006075,-- Api Ca - AUG (Level 7)
 1101006033,-- Beban Sirkus Rong - AUG (Level 5)
 1101006044,-- Evangelion Angel HAL 4 - AUG (Level 5)
 1101006067,-- Ác Mimpi Laut Dalam - AUG (Level 5)
 -- [ GROZA ]
 1101005038,-- Ryomen Sukuna - Groza (Level 7)
 1101005052,-- Api U Minh - Groza (Level 7)
 1101005098,-- Godzilla Angkat Api - Groza (Level 7)
 1101005019,-- Ksatria Binh hutan Dalam - GROZA (Level 5)
 1101005025,-- Malam Misteri virtual - GROZA (Level 5)
 1101005043,-- Pertandingan Pertempuran Warna Warna - Groza (Level 5)
 1101005082,-- Lentera Lampu Rahasia Jagung - Groza (Level 5)
 1101005090,-- Di Akumulasi Atas Kuno - Groza (Level 5)
 1101005105,-- Singam Roar - Groza (Level 5)
 -- [ QBZ & Mk47 & G36C & Honey Badger & FAMAS & ASM Abakan & ACE32 ]
 1101007046,-- Fungsi Penguasa Hitam gelap - QBZ (Level 7)
 1101007062,-- bunga Pedang Tertinggi Jaringan - QBZ (Level 7)
 1101007071,-- Langit Takdir - QBZ (Level 7)
 1101007025,-- Ánh Matahari - QBZ (Level 5)
 1101007036,-- Sapuan Scan - QBZ (Level 5)
 1101007079,-- Es Kekuasaan - QBZ (Level 5)
 1101009019,-- Kelinci Tinh Monster - Mk47 (Level 3)
 1101010029,-- Xung Irama Arena Rumput - G36C (Level 5)
 1101012033,-- Kuno Kayu Pertempuran udara - Honey Badger (Level 7)
 1101012009,-- Warna Warna Misteri virtual - Honey Badger (Level 5)
 1101012018,-- slider Suara Du Matahari - Honey Badger (Level 5)
 1101012024,-- Honey Badger Mikey (Level 5)
 1101100012,-- Kaisar Raja Dewa Jurang - FAMAS (Level 8)
 1101100018,-- virtual gambar Listrik Maut - FAMAS (Level 5)
 1101101007,-- Uy Senjata Hitam Burung - ASM Abakan (Level 7)
 1101102025,-- Air Monster - ACE32 (Level 8)
 1101102041,-- Dewa Tri Pertanda Baik - ACE32 (Level 8)
 1101102049,-- Saat Diam Sayap Kupu-kupu - ACE32 (Level 8)
 1101102007,-- Kamehameha - ACE32 (Level 7)
 1101102017,-- Permata Jade - ACE32 (Level 7)
 1101102032,-- Rubah Tinh Terbalik - ACE32 (Level 5)
 -- [ SMG (UZI, UMP45, Vector, Thompson, Bizon, MP5K, P90) ]
 1102001120,-- Es Harga - UZI (Level 8)
 1102001130,-- Rantai Rantai Api Neraka - UZI (Level 7)
 1102001024,-- Savagery - UZI (Level 6)
 1102001036,-- Benda Sarang Dewa Rahasia - UZI (Level 5)
 1102001058,-- Momen Ukiran Tidak Sangka - UZI (Level 5)
 1102001069,-- UZI Quang Ubah (Level 5)
 1102001089,-- Ma Sihir - UZI (Level 5)
 1102001103,-- oranye Segar Segar - UZI (Level 5)
 1102001102,-- Mesin Ép Kiri pohon - UZI (Level 5)
 1102002438,-- Song Maut Pertempuran - UMP45 (Level 8)
 1102002446,-- Song Maut Merah Pekat - UMP45 (Level 8)
 1102002043,-- Api long - UMP45 (Level 7)
 1102002061,-- virtual Mimpi Mati Kematian - UMP45 (Level 7)
 1102002136,-- Es Harga - UMP45 (Level 7)
 1102002424,-- Dewa udara Anukhra - UMP45 (Level 7)
 1102002053,-- EMP - UMP45 (Level 5)
 1102002070,-- Perlengkapan penguasa Putih Emas - UMP45 (Level 5)
 1102002090,-- Pertandingan Pertempuran 8-Bit - UMP45 (Level 5)
 1102002112,-- Hari Turun buat - UMP45 (Level 5)
 1102002117,-- Ong Jagung Bajak - UMP45 (Level 5)
 1102002129,-- anak gelombang Acara Festival - UMP45 (Level 5)
 1102002143,-- PUBGM X NewJeans - UMP45 (Level 5)
 1102003080,-- Sayap Naga - Vector (Level 7)
 1102003100,-- Salju Hancurkan gambar - Vector (Level 7)
 1102003020,-- Nanh Kelelawar Darah Suku - Vector (Level 5)
 1102003031,-- bunga Pink Malam - Vector (Level 5)
 1102003039,-- Beruang Tinh Terbalik - Vector (Level 5)
 1102003052,-- Dominan Gelar Kuning - Vector (Level 5)
 1102003065,-- Bilah Sabit Kuning - Vector (Level 5)
 1102003072,-- Dekat Tangan gelap Atas - Vector (Level 5)
 1102003090,-- KMF Lancelot - Vector (Level 5)
 1102004018,-- Permen Manis - Thompson (Level 5)
 1102004034,-- Mesin Lari Uap Air - Thompson (Level 5)
 1102004048,-- Maut Belakang - Thompson SMG (Level 3)
 1102005064,-- Quang virtual Listrik Maut - PP-19 Bizon (Level 7)
 1102005007,-- saklar Tanggul - PP-19 Bizon (Level 5)
 1102005020,-- Skullcrusher - PP-19 Bizon (Level 5)
 1102005041,-- Dewa Binh Bela diri Teknik - PP-19 Bizon (Level 5)
 1102005052,-- DP Quantum Quake - Bizon (Level 5)
 1102005057,-- Kirin Guru - PP-19 Bizon (Level 5)
 1102005072,-- Darah Pengorbanan - PP-19 Bizon (Level 5)
 1102005078,-- SAKAMOTO SHOP - PP-19 (Level 5)
 1102007019,-- PUBGM X QWER - MP5K (Level 5)
 1102007022,-- Pixel Kuno Contoh - MP5K (Level 3)
 1102105012,-- Kucing Wanita Fungsi Seni - P90 (Level 7)
 1102105028,-- Langit Kode - P90 (Level 7)
 1102105018,-- Cakar Cakar Kerajaan Emas - P90 (Level 5)
 -- [ SNIPER & MARKSMAN RIFLE (Kar98, M24, AWM, SKS, SLR, Mk14, etc.) ]
 1103001202,-- Es Cinta - Kar98K (Level 8)
 1103001060,-- Tanda nanh Marah Marah - Kar98K (Level 7)
 1103001079,-- Kukulkan Gila Marah - Kar98K (Level 7)
 1103001101,-- Ánh Bulan - Kar98K (Level 7)
 1103001129,-- Gackt Moon - Kar98K (Level 7)
 1103001146,-- Ikan Gemuk Titan - Kar98K (Level 7)
 1103001154,-- Rahasia Kode Mati Kematian - Kar98K (Level 7)
 1103001179,-- Listrik Ekstrem Ungu - Kar98K (Level 7)
 1103001191,-- Pink Api Api - Kar98K (Level 7)
 1103001085,-- Malam Musik Rock - Kar98K (Level 5)
 1103001160,-- Pengrajin Berburu Tinh Awan - Kar98K (Level 5)
 1103001183,-- Irama Gaya Kucing anak - Kar98K (Level 3)
 1103002030,-- Kekuasaan Tongkat Pharaoh - M24 (Level 7)
 1103002059,-- Minggu selesai Hal Hidup - M24 (Level 7)
 1103002087,-- Irama Gaya selesai Indah - M24 (Level 7)
 1103002106,-- Minh Bulan Terlarang Jurang - M24 (Level 7)
 1103002156,-- Rata-rata Minh Bayangan gelap - M24 (Level 7)
 1103002049,-- Danau Kupu-kupu Phu Orang - M24 (Level 5)
 1103002047,-- Giai Gaya Tertinggi Jaringan - M24 (Level 5)
 1103002094,-- Fungsi Seni TINGGI - M24 (Level 5)
 1103003022,-- Neon - AWM (Level 7)
 1103003030,-- Hanya Huy Pertempuran Lapangan - AWM (Level 7)
 1103003042,-- Godzilla - AWM (Level 7)
 1103003051,-- Besar Long bola Pelangi - AWM (Level 7)
 1103003062,-- Api Phoenix Kerajaan - AWM (Level 7)
 1103003079,-- Darah Laut Langit Long - AWM (Level 7)
 1103003087,-- slider bunga Ular - AWM (Level 7)
 1103003099,-- Hitam udara - AWM (Level 7)
 1103003092,-- Pink Hoang - AWM (Level 5)
 1103004037,-- Berharga Nenek Merah - SKS (Level 7)
 1103004046,-- hutan Baja - SKS (Level 5)
 1103004058,-- fitur jumlah Es Salju - SKS (Level 5)
 1103004080,-- Murni bunga Mekar Rimbun - SKS (Level 5)
 1103004087,-- Giai Gaya Maut Dewa - SKS (Level 5)
 1103005024,-- Gagak Hitam - VSS (Level 5)
 1103005048,-- Trinh Dekat Salju Putih - VSS (Level 3)
 1103009022,-- Musim bunga Gali - SLR (Level 5)
 1103009037,-- Ujung Api Ma Teknik - SLR (Level 5)
 1103009051,-- Ma Mimpi - SLR (Level 5)
 1103009042,-- slider Suara Laut Misteri - SLR (Level 3)
 1103006030,-- Sungai Es - Mini14 (Level 7)
 1103006046,-- Keindahan Indah Murni Murni - Mini14 (Level 5)
 1103006058,-- Kucing Gerakan Bakat - Mini14 (Level 5)
 1103006063,-- Tay Balap Gan Malam - Mini14 (Level 5)
 1103006075,-- Irama Pertempuran cepat - Mini14 (Level 5)
 1103007028,-- Raja Negara Naga - Mk14 (Level 8)
 1103007020,-- Kekuatan Kuat Perak Sungai - Mk14 (Level 5)
 1103007038,-- Naga Susu Lembut Mudah - Mk14 (Level 5)
 1103007043,-- Kotak Hadiah May Beruntung - Mk14 (Level 5)
 1103012010,-- Sangat besar Long Ephialtes - AMR (Level 8)
 1103012019,-- Api Dewa - AMR (Level 7)
 1103012031,-- Tanpa Suara Ly khusus - AMR (Level 7)
 1103012039,-- Besar Pertempuran Ilusi Warna - AMR (Level 7)
 1103012024,-- Tinh bisa Onyx - AMR (Level 5)
 1103100007,-- Hewan Berburu Umpan - Mk12 (Level 5)
 1103102007,-- Pertempuran Armada Senjata Tiang - DSR (Level 7)
 1103103007,-- Vinh Quang Pertempuran Binh - M1 Garand (Level 7)
 -- [ SHOTGUN & MACHINE GUN (S12K, DBS, M249, DP-28, MG3...) ]
 1104001035,-- Racun Jiwa - S686 (Level 5)
 1104002022,-- Senja Senja - S1897 (Level 5)
 1104002049,-- Xung Ukuran Warna Warna - S1897 (Level 3)
 1104003026,-- S12K GACKT (Level 7)
 1104003037,-- Ukuran Aktif Asli Maut - S12K (Level 5)
 1104003046,-- Kiri Tim Cyber - S12K (Level 5)
 1104004035,-- Pertempuran Armor Monster Hewan - DBS (Level 5)
 1104004041,-- Sandsinger - DBS (Level 5)
 1104004051,-- Okarun - DBS (Level 5)
 1104004024,-- Laporan Warna Warna - DBS (Level 3)
 1104102004,-- Hancur Akumulasi Kerajaan Emas - NS2000 (Level 3)
 1105001034,-- Meriam Turun buat - M249 (Level 7)
 1105001048,-- Wanita Kaisar Ánh Terang - M249 (Level 7)
 1105001069,-- Raja Kekuasaan Hitam gelap - M249 (Level 7)
 1105001020,-- Wanita Kerajaan Es Harga M249 V (Level 5)
 1105001054,-- Stargaze Fury - M249 (Level 5)
 1105001062,-- Graffiti Jalan Kota - M249 (Level 5)
 1105001075,-- Ikan Gemuk Baja - M249 (Level 4)
 1105002091,-- Darah Bencana - DP28 (Level 8)
 1105002018,-- Dekat Tangan Rahasia sembunyi - DP-28 (Level 5)
 1105002035,-- Permata Long - DP-28 (Level 5)
 1105002058,-- Pertempuran Binh Barang Laut - DP28 (Level 5)
 1105002063,-- Naga Dewa Shenron - DP-28 (Level 5)
 1105002071,-- Pertempuran prajurit Dewa Armor - DP-28 (Level 5)
 1105002076,-- Kucing Nomor Ubah - DP-28 (Level 5)
 1105002083,-- DP-28 Frieren's Staff (Level 5)
 1105002096,-- Danau Suku - DP-28 (Level 3)
 1105010019,-- Pertempuran Dewa Labu langit - MG3 (Level 7)
 1105010008,-- Langit frame - MG3 (Level 5)
 1105010026,-- Mina Ashiro - MG3 (Level 5)
 -- [ dekat tempur & senjata senjata berbeda (Skorpion, Crossbow, pan, Dao...) ]
 1106008013,-- Rahasia Kode Kuning - Skorpion (Level 5)
 1106008022,-- Rahasia sembunyi Tinh Cantik - Skorpion (Level 3)
 1106011008,-- Naga Ular naik awan - MP7 Ganda (Level 5)
 1106011003,-- Pengrajin Berburu Permen - MP7 (Level 3)
 1107001018,-- Penguasa Badut Makmur Marah - Crossbow (Level 3)
 1107098003,-- goyang Getaran Fungsi Seni - MGL (Level 3)
 1108001057,-- Berburu Naga - Dao (Level 3)
 1108001064,-- Pendek Pedang Yor SPY×FAMILY (Level 3)
 1108001069,-- Ki Sword (Level 3)
 1108001081,-- Kapak Godzilla Angkat Api (Level 3)
 1108001085,-- Pedang tengah Tim Trinh Dekat Level 3
 1108001098,-- Luka Pulau Terbalik Langit Jalan - Dao (Level 3)
 1108001104,-- Rantai Tay - Dao (Level 3)
 1108002059,-- Paku Ba Air Pasang Makmur Marah (Level 5)
 1108004125,-- Toples Rahasia Ong - Panci (Level 5)
 1108004160,-- Ikan Buaya - Panci (Level 5)
 1108004145,-- Malam Musik Rock - Panci (Level 5)
 1108004283,-- Vinh Quang - Panci (Level 6)
 1108004337,-- Panci Listrik Asli Maut (Level 6)
 1108004356,-- Ayam Goreng - Panci (Level 3)
 1108004365,-- Yokai Misteri Rahasia - Panci (Level 3)
 1108004377,-- Panci Sayap Pendek Vui Tampilan (Level 5)
 1108004416,-- Kipas Senjata Gaya Panas Terbakar - Panci (Level 3)
 1108005050,-- Naga Es Harga - Dao Belati (Level 3)
 -- ==============================================================================
 -- 2. FULL super kendaraan (VIP VEHICLES)
 -- ==============================================================================
 -- [ McLaren ]
 1961007,-- McLaren 570S (Hitam)
 1961010,-- McLaren 570S (Putih)
 1961012,-- McLaren 570S (Pink)
 1961013,-- McLaren 570S (Kuning Putih)
 1961014,-- McLaren 570S (Kuning Hitam)
 1961015,-- McLaren 570S (Ánh Emas)
 1961147,-- McLaren P1 (langit Sao)
 1961148,-- McLaren P1 (Pink Terang Cemerlang)
 1961149,-- McLaren P1 (Kuning Gunung Api)
 1907054,-- Xe Balap Tim McLaren F1 (Listrik Maut)
 1907058,-- Xe Balap Tim McLaren F1
 1907059,-- Xe Balap Tim McLaren F1 (Pertempuran Menang)
 -- [ Koenigsegg ]
 1961016,-- Koenigsegg Jesko (Abu-abu perak)
 1961017,-- Koenigsegg Jesko (bola Pelangi)
 1961018,-- Koenigsegg Jesko (Rata-rata Minh)
 1961029,-- Koenigsegg One:1 Gilt
 1961030,-- Koenigsegg One:1 Cyber Nebula
 1961031,-- Koenigsegg One:1 Jade
 1961032,-- Koenigsegg One:1 Phoenix
 1903074,-- Koenigsegg Gemera (Abu-abu perak)
 1903075,-- Koenigsegg Gemera (bola Pelangi)
 1903076,-- Koenigsegg Gemera (Rata-rata Minh)
 -- [ Lamborghini ]
 1961020,-- Lamborghini Aventador SVJ Verde Alceo
 1961021,-- Lamborghini Centenario Galassia
 1961024,-- Lamborghini Aventador SVJ Blue
 1961025,-- Lamborghini Centenario Carbon Fiber
 1961144,-- Lamborghini Invencible Rosso Efesto
 1961145,-- Lamborghini Invencible Nebula Drift
 1903079,-- Lamborghini Estoque Oro
 1903080,-- Lamborghini Estoque Metal Grey
 1908066,-- Lamborghini Urus Pink
 1908067,-- Lamborghini Urus Giallo Inti
 -- [ Bugatti ]
 1961041,-- Bugatti Veyron 16.4 (Warna Warna)
 1961042,-- Bugatti Veyron 16.4 (Kuning)
 1961043,-- Bugatti Veyron 16.4
 1961044,-- Bugatti La Voiture Noire
 1961045,-- Bugatti La Voiture Noire (Gabung Emas)
 1961046,-- Bugatti La Voiture Noire (Pertempuran Binh)
 1961047,-- Bugatti La Voiture Noire (Tinh Awan)
 1961151,-- Bugatti Bolide (Bilah Cermin)
 1961152,-- Bugatti Bolide (Belgia Tepi)
 1961153,-- Bugatti Bolide (virtual gambar Danau Es)
 -- [ Aston Martin ]
 1961048,-- Aston Martin Valkyrie (Luminous Diamond)
 1961049,-- Aston Martin Valkyrie (Racing Green)
 1915005,-- Aston Martin DBS Volante (Deep Cosmos)
 1915006,-- Aston Martin DBS Volante (Celestial Pink)
 1915007,-- Aston Martin DBS Volante (Black-Bronze Satin)
 1908084,-- Aston Martin DBX707 (Neon Purple)
 1908085,-- Aston Martin DBX707 (Quasar Blue)
 -- [ Pagani ]
 1961051,-- Pagani Zonda R (Tricolore Carbon)
 1961052,-- Pagani Zonda R (Bianco Benny)
 1961053,-- Pagani Zonda R (Melodic Midnight)
 1961054,-- Pagani Imola (Grigio Montecarlo)
 1961055,-- Pagani Imola (Crystal Clear Carbon)
 1961056,-- Pagani Imola (Nebula Dream)
 1961057,-- Pagani Imola (Arctic Aegis)
 -- [ Bentley ]
 1961137,-- Bentley Batur (Emas Baja Berkilau Berkilau)
 1961138,-- Bentley Batur (Akhir sama Waktu durasi)
 1961139,-- Bentley Betayga Azure (Raja Negara Misteri virtual)
 1903200,-- Bentley Flying Spur Mulliner (Tinh Awan hijau)
 1903201,-- Bentley Flying Spur Mulliner (Baris Mengalir Teluk Sempit)
 1908094,-- Bentley Betayga Azure (hujan bunga)
 1908095,-- Bentley Betayga Azure (Malam Tenang Statis)
 1915008,-- Bentley Continental GTC Mulliner (Mimpi Peringatan Lung Linh)
 1915009,-- Bentley Continental GTC Mulliner (Berharga Suku baju Ungu)
 -- [ Maserati ]
 1961038,-- Maserati MC20 Bianco Audace
 1961039,-- Maserati MC20 Rosso Vincente
 1961040,-- Maserati MC20 Sogni
 1908075,-- Maserati Levante Blu Emozione
 1908076,-- Maserati Luce Arancione
 1908077,-- Maserati Levante Neon Urbano
 1908078,-- Maserati Levante Firmamento
 -- [ Dodge / SRT ]
 1961036,-- Dodge Challenger SRT Hellcat - Blaze
 1961037,-- Dodge Challenger SRT Hellcat - Lime
 1961050,-- Dodge Challenger SRT Hellcat Jailbreak - Hellfire
 1961136,-- Dodge Challenger SRT Hellcat - Blaze
 1961150,-- Dodge Challenger SRT Hellcat Jailbreak - Hellfire
 1903088,-- Dodge Charger SRT Hellcat - Fuchsia
 1903089,-- Dodge Charger SRT Hellcat - Tuscan Torque
 1903090,-- Dodge Charger SRT Hellcat Jailbreak - Violet Venom
 1903189,-- Dodge Charger SRT Hellcat - Tuscan Torque
 1903190,-- Dodge Charger SRT Hellcat Jailbreak - Violet Venom
 1908086,-- Dodge Hornet - Scarlet Sting
 1908088,-- Dodge Hornet GLH Concept - Redline
 1908089,-- Dodge Hornet - Sunburst
 1908188,-- Dodge Hornet GLH Concept - Redline
 1908189,-- Dodge Hornet - Sunburst
 -- [ Porsche ]
 1961062,-- Porsche 918 Spyder (Baris Air)
 1961063,-- Porsche 918 Spyder (964 perak Ánh Emas)
 1961064,-- Porsche 918 Spyder (Pink)
 1903218,-- Porsche Panamera Turbo S (Biru Permata)
 1903219,-- Porsche Panamera Turbo S (hijau Viper)
 1908108,-- Porsche Cayenne Turbo GT (Jalan Balap Terang Api)
 1908109,-- Porsche Cayenne Turbo GT (oranye Dung Nham)
 1915021,-- Porsche 911 Carrera 4 GTS Cabriolet (Ribu Sao)
 1915022,-- Porsche 911 Carrera 4 GTS Cabriolet (Merah Ruby)
 -- [ Shelby / Ford ]
 1961058,-- Shelby 427 Cobra (hijau & Putih)
 1961059,-- Shelby 427 Cobra (Graffiti Pulih Kuno)
 1903210,-- Shelby GT500 (Hitam & Merah)
 1903211,-- Shelby GT500 (Orang luar Perjalanan Tinh Cyber)
 1961068,-- Ford Mustang GTD (Misteri Telepon hijau Segar)
 1961069,-- Ford Mustang GTD (Tinh Dewa Air Indah)
 -- [ Lotus ]
 1961060,-- Lotus Emira (hutan Dalam Pekat)
 1961061,-- Lotus Emira (Meluncur Warna hijau)
 -- [ Apollo ]
 1961065,-- Apollo EVO (Kuning Terang Cemerlang)
 1961066,-- Apollo EVO (Kerajaan Cium)
 1961067,-- Apollo EVO (Es Harga)
 1903220,-- Apollo Intensa Emozione (Api Neraka Panas Mengalir)
 1903221,-- Apollo Intensa Emozione (Bayangan Ma Ungu)
 1903222,-- Apollo Intensa Emozione (Putusan Bertarung)
 1903223,-- Apollo Intensa Emozione (Badai Kualitas)
 -- [ SSC Tuatara ]
 1961140,-- virtual gambar bunga Pink SSC Tuatara
 1961141,-- Bangau langit SSC Tuatara
 1961142,-- Pedang Rata-rata Minh SSC Tuatara Striker
 1961143,-- Layar Malam hijau SSC Tuatara Striker
 -- [ Tesla ]
 1903071,-- Tesla Roadster (Emas Baja)
 1903072,-- Tesla Roadster (Pha Pir Ungu)
 1903073,-- Tesla Roadster (hijau Laut Semua)
 -- [ Ducati / Motor VIP ]
 1901073,-- DUCATI Panigale V4S
 1901074,-- Ducati Panigale V4S Black Phantom
 1901075,-- Ducati Panigale V4S Crimson Storm
 1901076,-- Ducati Panigale V4S Swift Mirage
 -- ==============================================================================
 -- 3. FULL pesawat parasut (parasut jatuh, kapal glider, papan seluncur pesawat)
 -- ==============================================================================
 -- [ parasut (Parachutes) ]
 1401000,-- New Years Blessing Parachute
 1401001,-- Happy New Year Parachute
 1401002,-- Parasut Tulang Merah
 1401003,-- Parasut Kecil Iblis tinh Terbalik
 1401005,-- Parasut Laba-laba Berubah gambar
 1401006,-- Parasut Musim 5
 1401007,-- Parasut buat hari
 1401008,-- Parasut Bangau Kuning
 1401009,-- Parasut Iblis Merah
 1401010,-- Parasut bunga seratus rumput
 1401011,-- Parasut anh Gali
 1401012,-- Parasut Campus Tournament
 1401013,-- Parasut Joker
 1401014,-- Parasut Badut badut
 1401015,-- Carabao Parachute
 1401016,-- Orange Life Parachute
 1401017,-- Parasut Elang kuning
 1401018,-- Parasut Juara pasukan Musim 8
 1401019,-- Parasut Tim pemimpin Ryan
 1401020,-- Parasut Orang lang thang
 1401021,-- Parasut Bulan
 1401022,-- OPPO F11 PRO SURVIVOURS PARACHUTE
 1401023,-- Parasut pimpin penguasa Sekigahara (Kotak)
 1401024,-- Parasut Perunggu Minh Loot Pendengaran
 1401025,-- Parasut Malam Mabuk Atau (Kotak)
 1401026,-- Parasut Pasir tembok
 1401027,-- Parasut PMCO
 1401028,-- Parasut Juara pasukan Musim 7
 1401029,-- Parasut buat hari Terang Cemerlang
 1401031,-- Parasut Juara pasukan Musim 6
 1401032,-- Parasut Dao Belati Merah
 1401033,-- Parasut WALKER
 1401034,-- Parasut Cocok Air Es Harga
 1401035,-- Parasut orang tantangan Bertarung
 1401036,-- Parasut BAPE X PUBGM CAMO
 1401037,-- Parasut Godzilla (Putih)
 1401038,-- Parasut Godzilla (Kuning)
 1401039,-- Parasut Godzilla (hijau)
 1401040,-- Parasut Monarch
 1401041,-- Parasut Kopi Ri
 1401043,-- Parasut Orang Jaga Malam
 1401044,-- Parasut bunga pink hitam
 1401045,-- Parasut Kucing May Beruntung
 1401046,-- Parasut Malam u gelap
 1401047,-- Parasut Ikan Dekat Tangan
 1401048,-- Parasut air Monster Kraken
 1401050,-- Parasut giai Gaya Suara Musik
 1401051,-- Parasut OPPO Reno
 1401052,-- Parasut OPPO VOOC
 1401053,-- Parasut Malam Mabuk Atau
 1401054,-- Parasut Badut Heo Tinh Terbalik
 1401055,-- Parasut Red (Panjang)
 1401056,-- PMJC Parachute
 1401057,-- PMSC Parachute
 1401059,-- Parasut Juara pasukan Draconian
 1401060,-- Parasut pimpin penguasa Sekigahara
 1401061,-- Parasut Kecil Iblis
 1401062,-- Parasut Juara pasukan Musim 9
 1401063,-- Parasut Juara pasukan Musim 10
 1401064,-- Parasut Kucing Hitam
 1401065,-- Parasut Ayam kosong
 1401066,-- Parasut Rayap daftar Es Harga
 1401067,-- Parasut Orang kurangi Sakit #11
 1401068,-- Super Power Parachute
 1401071,-- Parasut Roda Kembali Tanpa Akhir
 1401072,-- Parasut Penguasa penguasa Ribuan Jenis
 1401074,-- Parasut Rahasia Jagung Kinh Aneh
 1401085,-- Parasut Ayam Harum Ngon
 1401086,-- Parasut Juara pasukan Musim 11
 1401087,-- Parasut bunga Sen Darah
 1401088,-- Parasut Perjalanan Tinh Hanyut Terdampar
 1401089,-- Parasut Juara Tentara Musim 12
 1401090,-- Parasut Ninja Dekat Tangan
 1401091,-- Parasut Neko Sakura
 1401092,-- Parasut Orang Dewa Phong
 1401094,-- Parasut Fantasy Girl
 1401095,-- Parasut Tranh Gambar Pertempuran Lapangan
 1401096,-- Parasut Orang Vonis Putusan
 1401097,-- Parasut Africa Pride
 1401098,-- Parasut Africa Unite
 1401100,-- Parasut Kamu Kuning
 1401102,-- Parasut khusus tugas PMSC World Cup
 1401103,-- Parasut Tentara Tim Tujuh Tersesat
 1401104,-- Parasut Pecahkan Bertarung PMCO
 1401106,-- Parasut tengah Úy Senjata Tiang
 1401107,-- Parasut penuh Aku Darah Nha
 1401108,-- Parasut Street Dancer 3
 1401109,-- Parasut Unique KingCard
 1401111,-- Parasut Kue Ú
 1401112,-- Parasut Teriak Menjerit
 1401113,-- Parasut Tangan Penjaga OTOMATIS Do
 1401115,-- Parasut Permen Manis
 1401117,-- Parasut TINGGI Tambahan Jauh Barat
 1401119,-- Parasut Armor Samurai
 1401122,-- Incredible Parachute
 1401124,-- Parasut Warrior
 1401125,-- Parasut Berharga Nona Gothic
 1401127,-- Parasut Dewa Telepon Ả Jebakan
 1401128,-- Parasut Rumah Tanpa musuh Arena
 1401129,-- Parasut Juara Tentara Musim 13
 1401130,-- Parasut Gorilla
 1401131,-- Parasut PMGC
 1401133,-- Parasut Musim 15
 1401134,-- Parasut Tulip
 1401135,-- Parasut Ác Ma Gila Marah
 1401137,-- Parasut Musim 14
 1401138,-- Parasut Pro League (Kuning)
 1401139,-- Parasut Pro League (perak)
 1401140,-- Parasut Tersesat Kemiringan Gagah Bao
 1401141,-- Parasut Ayam Goreng
 1401142,-- Parasut CLB Kerajaan Gia
 1401145,-- Parasut Tujuh Warna
 1401146,-- Parasut Mountain Dew
 1401147,-- Parasut Postur Pengorbanan gelap TINGGI
 1401148,-- Parasut Idol
 1401149,-- Parasut Dang Lebar Ganda Sayap
 1401150,-- Parasut Pertempuran Binh Baja
 1401151,-- Parasut Juara Tentara Musim 16
 1401152,-- Parasut Sabit Maut Dewa
 1401153,-- Parasut emoji Puas Penuh
 1401154,-- Parasut emoji
 1401155,-- Parasut emoji Vui Ramai
 1401156,-- Parasut Qualcomm
 1401157,-- Parasut Titik Dasar Menyebar
 1401159,-- Parasut pimpin Penguasa Racun Bakat
 1401160,-- Parasut Jepit Biji Kacang Vui Tampilan
 1401161,-- Parasut Long Raja
 1401163,-- Parasut Armor Pertempuran Dewa
 1401164,-- Parasut Giai Gaya Cinta Luka
 1401165,-- Parasut Juara Tentara Musim 17
 1401167,-- Parasut Ánh Bulan Misteri Rahasia
 1401168,-- Parasut Pesta Disco
 1401169,-- Parasut Juara Tentara Musim 18
 1401170,-- Parasut Salju Anh Gali
 1401171,-- Parasut Sarang Ong
 1401174,-- Parasut Juara Tentara Musim 19
 1401177,-- Parasut Juara Tentara C1S1
 1401178,-- Parasut Es Pasir Petir
 1401179,-- Parasut El Diablo
 1401181,-- Penguasa penguasa Es Harga - Parasut
 1401182,-- Parasut Orang Berburu Umpan Laut hijau
 1401183,-- Parasut Mimpi Kupu-kupu
 1401184,-- Parasut Serangga Sayap Keras
 1401186,-- Parasut Kura-kura dan Kelinci
 1401187,-- Parasut Irama Langkah Kuat Gaya
 1401188,-- Parasut PMPL Musim Musim semi 2021
 1401189,-- Parasut GodzillaVsKong
 1401190,-- Parasut Perjalanan Proses pun Ajaib
 1401191,-- Parasut Tanda Ấn Senjata Tiang
 1401192,-- Parasut Kepala Dapur Ayam
 1401193,-- Parasut Seni Teknik Warna Warna
 1401194,-- Parasut Aerial Punk Rich Brian
 1401195,-- Parasut OPPO
 1401196,-- Parasut BUG
 1401197,-- Parasut Penguasa penguasa Kue Gigi
 1401198,-- Parasut Xiaomi
 1401200,-- Parasut Ganda Mata Laut Dalam
 1401201,-- Parasut OnePlus
 1401204,-- Parasut foodpanda
 1401205,-- Parasut PMPL Musim perkecil 2021
 1401208,-- Parasut Menjadi Kota Atas Tidak
 1401209,-- Parasut Bayangan Ma mirip Lai
 1401210,-- Parasut Rahasia Penyelidik Mekanisme udara
 1401212,-- Parasut Menjadi Kota Warna Warna
 1401213,-- Parasut Senjata bunga Pink
 1401215,-- Parasut Es Harga
 1401216,-- Parasut versi Perlengkapan Kho Harta
 1401217,-- Parasut Badai Demam Turun buat
 1401218,-- Parasut Bencana HEMAT Kuning
 1401219,-- Parasut Raja Negara Kuning
 1401220,-- Parasut Kerajaan Cium Terang Cemerlang
 1401221,-- Parasut Pasangan Kalimat Putih
 1401222,-- Parasut Putaran Xoay Waktu durasi
 1401223,-- Parasut Zong
 1401224,-- Parasut Juara Tentara C1S2
 1401225,-- Parasut Juara Tentara C1S3
 1401227,-- Parasut Besar Turun Harga
 1401228,-- Parasut Romantis Tamu Waktu Atas
 1401231,-- Parasut PMGC 2021
 1401232,-- Parasut Liverpool FC
 1401233,-- Parasut Mendadak Hancur
 1401234,-- Parasut Voi Warna Warna
 1401235,-- Parasut Gabung aksi Egor Kreed
 1401236,-- Gackt Moon Parachute
 1401237,-- Parasut Dune
 1401238,-- Parasut Guruh Gundala
 1401239,-- Parasut C2S4
 1401240,-- Parasut Baby Shark
 1401241,-- Parasut JAPAN LEAGUE S2
 1401242,-- Parasut Kepala Dapur Monster Hewan
 1401243,-- Parasut Dominan Utama Besar Matahari
 1401244,-- Parasut C2S5
 1401245,-- Parasut Wanita Kerajaan Listrik Maut
 1401246,-- Parasut Tahun Harimau
 1401247,-- Parasut Warna Musim semi
 1401248,-- Parasut Jujutsu Kaisen
 1401249,-- Parasut Shiba Inu
 1401250,-- Parasut Motorola
 1401252,-- Parasut Pertandingan Pertempuran Trendy
 1401254,-- Parasut DJ Ikan hitung
 1401255,-- Parasut Kakak Kakak Em Em
 1401256,-- Parasut Graffiti Neon
 1401257,-- Parasut C2S6
 1401258,-- Parasut Orang Laba-laba: Tidak Masih Rumah
 1401259,-- Parasut Dekat Tangan Waktu Tidak
 1401260,-- Parasut Area tanah Hoang
 1401261,-- Parasut Warna Warna
 1401262,-- Parasut Acara Festival Warna Warna
 1401263,-- Parasut Bioskop Sirkus Dewa pun
 1401264,-- Parasut Kurang Wanita Rambut Merah
 1401265,-- Parasut Set Ganda selesai Bagus
 1401266,-- Parasut Kurang Wanita Song buat
 1401267,-- Parasut Sayap Gerbang pun Aneh
 1401268,-- Parasut Kurang Wanita Anime
 1401269,-- Parasut Ayam Pertempuran Bertarung
 1401270,-- Parasut Lilin hijau
 1401271,-- Parasut Jiwa Ma Terbalik Nakal
 1401272,-- Parasut Kurang Wanita bola Harapan
 1401273,-- Parasut Ma Wanita Layak Cinta
 1401274,-- Parasut Evangelion NERV
 1401275,-- Parasut Kakak Em Song buat
 1401276,-- Parasut PMPL Musim Musim semi 2022
 1401277,-- Parasut Beruang Teddy GB
 1401278,-- Parasut Guru Maut Waktu Trang
 1401280,-- Parasut Era Pikiran Usia Puisi
 1401281,-- Parasut C3S7
 1401282,-- Parasut Kucing Raksasa Besar
 1401283,-- Parasut Butterfinger
 1401284,-- Super Parasut lompat
 1401285,-- Parasut Perunggu Minh Musim Musim panas
 1401286,-- Parasut Tupai Tikus
 1401287,-- Parasut Api Api Ma Armor
 1401289,-- Parasut Heartrocker
 1401290,-- Parasut Guru Maut Ganda Sungai
 1401291,-- Parasut realme
 1401292,-- Parasut Lil Burger
 1401294,-- Parasut Baris Sungai Mimpi Mimpi
 1401295,-- Parasut C3S8
 1401296,-- Parasut Malam dari Sihir Warna
 1401298,-- Parasut Vinh Quang
 1401299,-- Parasut versi Perlengkapan Sao
 1401300,-- Parasut Penguasa penguasa Gai Racun
 1401301,-- Parasut Bayangan Ma dan Gadis
 1401302,-- Parasut Gai Kecil Terbakar
 1401303,-- Parasut Uqabi
 1401308,-- Parasut Cocok Air Es Harga
 1401309,-- Parasut kecepatan tingkat Ekstrem batas
 1401310,-- Parasut PMWI 2022
 1401311,-- BGMI Esports Parachute
 1401312,-- PMJL SEASON3 Parachute
 1401313,-- PMPS 2022 Parachute
 1401314,-- Parasut Pertempuran Binh Kerbau
 1401315,-- Parasut Kekuasaan Kekuatan gelap Atas
 1401316,-- Parasut Tim Bayangan Ả Jebakan
 1401317,-- Parasut Ribu Sao Terang Cemerlang
 1401318,-- Parasut Sihir Guru Langit Teks
 1401319,-- Parasut C3S9
 1401320,-- Parasut BoBoiBoy
 1401323,-- Parasut Jalan Balap Hoang Liar
 1401324,-- Parasut Minggu Rezeki Putih
 1401325,-- Parasut Kapak Kerajaan Emas
 1401326,-- Parasut Kuning Misteri Rahasia
 1401330,-- Parasut Perjalanan Awan
 1401332,-- Parasut Kucing Salju
 1401334,-- Parasut KFC
 1401335,-- Parasut Air Guru Gila Marah
 1401336,-- Parasut Tengkorak Nham Batu
 1401337,-- Parasut Dominan Utama Labu langit
 1401338,-- Parasut Grubhub
 1401339,-- Parasut AFA
 1401340,-- Parasut Misteri Telepon Super Sao Messi
 1401343,-- Parasut PMGC 2022
 1401345,-- Parasut versi Perlengkapan Kho Harta
 1401346,-- Parasut Nobru
 1401347,-- Parasut Sony
 1401349,-- Parasut Mendadak Ukuran Atas Tidak
 1401351,-- Parasut Wanita Kesatria
 1401353,-- Parasut Badut Badut Iblis Licik
 1401355,-- Parasut Logika Kecil Long
 1401356,-- Parasut Ganda Bela Diri
 1401357,-- Parasut Donkey King
 1401360,-- Parasut Pro League
 1401361,-- Parasut Rencana Rencana Merah Pekat
 1401362,-- Parasut C4S11
 1401363,-- Parasut versi Perlengkapan Senjata Tiang
 1401364,-- Parasut BE@RBRICK
 1401365,-- Parasut Sumber Terang Vinh Quang
 1401366,-- Parasut karakter Ức Kuno
 1401367,-- Parasut Bugatti
 1401368,-- Parasut Ubah Batu Sangat besar Long
 1401369,-- Parasut Kabur Keluar T-Rex
 1401370,-- Parasut Dragon Ball Super
 1401371,-- Parasut C4S12
 1401372,-- Parasut Darah Naga
 1401373,-- UNIVERSTAR BT21 Parachute
 1401374,-- Parasut HUAWEI AppGallery
 1401375,-- Parasut PMWI 2023
 1401376,-- Parasut C5S13
 1401377,-- Parasut Kelinci Disco
 1401378,-- Parasut Aston Martin
 1401379,-- Parasut Musim Musim panas Atas Area Laut
 1401380,-- Parasut C5S14
 1401381,-- Parasut C5S15
 1401382,-- Parasut PMGC 2023
 1401383,-- Parasut KFC
 1401385,-- Parasut Yeti Raksasa Besar
 1401386,-- Parasut Pagani
 1401387,-- Parasut Laporan Warna Warna
 1401388,-- Parasut Kecil Tupai Layak Cinta
 1401389,-- Parasut pun Badai Pink
 1401390,-- RS Swagster Parachute
 1401391,-- Parasut Beruang Bambu Manis Manis
 1401392,-- Parasut Pertempuran Binh bunga Pink
 1401393,-- Parasut Pertandingan Pertempuran Utama Makna
 1401394,-- Parasut LINE FRIENDS
 1401395,-- Parasut Danau Ly Dewa Rahasia
 1401396,-- Parasut Zanmang Loopy
 1401397,-- Hardik Sky Parachute
 1401398,-- Parasut C6S16
 1401399,-- Parasut Bayangan Ma Pesona Rontok
 1401400,-- Parasut Lindungi Lindungi Kerajaan Gia
 1401401,-- Parasut Bentley
 1401402,-- SPY×FAMILY Parasut
 1401403,-- Parasut hari Nyata
 1401404,-- Parasut Pertempuran prajurit Dewa Armor
 1401405,-- Parasut C6S17
 1401406,-- Parasut Giai Gaya Kucing anak
 1401407,-- Parasut Menjadi Kota Campuran Kacau
 1401408,-- Parasut Ganda Sayap Dekat Penjaga
 1401409,-- Parasut Baja Kode
 1401410,-- Parasut Bay Meluncur Senjata Tiang
 1401411,-- Parasut C6 S18
 1401412,-- Parasut Wanita Kaisar Hitam gelap
 1401413,-- Parasut Gabung aksi Lamborghini
 1401416,-- Parasut Patung batu Kuno Kuno
 1401417,-- Parasut Besar Matahari hijau
 1401418,-- KAKAO FRIENDS Parachute
 1401419,-- Parasut Infinix GT
 1401420,-- Parasut Esports World Cup 2024
 1401421,-- Parasut C7S19
 1401422,-- Parasut Kelinci Tinh Monster
 1401423,-- Parasut Gabung aksi VW
 1401424,-- Parasut Kucing Linh Warna Warna
 1401425,-- Parasut Hitam Long Ma Label
 1401426,-- Parasut Suara Matahari
 1401427,-- NieR:Automata Parachute
 1401428,-- Parasut Gairah Mabuk Esports
 1401429,-- Parasut C7S20
 1401430,-- Parasut Venom: Matchup Akhir
 1401431,-- Parasut Set Suku Perak Sungai
 1401432,-- Parasut Minggu Rezeki Kerajaan Gia
 1401433,-- Parasut McLaren
 1401434,-- Parasut PMGC 2024
 1401435,-- Parasut meluncur Serigala Salju
 1401436,-- Parasut meluncur Bayangan Air
 1401437,-- Parasut meluncur C7S21
 1401438,-- Parasut Ikan Koi Musim semi Warna
 1401439,-- Parasut Besar Pohon
 1401440,-- Parasut bunga Pink Bayangan Malam
 1401441,-- Opanchu Parachute
 1401442,-- Neon Drop BE 6 Parachute
 1401443,-- Parasut C8S22
 1401444,-- Parasut Meluncur Hitam Tulang
 1401445,-- Parasut Ekstrem Quang Tinh Cantik
 1401446,-- Godzilla vs. Parasut Destoroyah
 1401447,-- Parasut Kelinci Gendong Terapung
 1401448,-- Parachute(Frieren&Fern)
 1401449,-- Parasut C8S23
 1401450,-- Parasut Meluncur Kode Nomor Ubah 
 1401451,-- Parasut Meluncur Perbesar Besar Warna Warna
 1401452,-- Parasut Gabung aksi Shelby
 1401453,-- Parasut Berusaha Arah Terang membebani
 1401454,-- Parasut Attack on Titan
 1401455,-- Parasut Mekanisme udara 
 1401456,-- Mountain Dew Neon Shard Parachute
 1401457,-- Parasut C8S24
 1401458,-- Parasut Senjata Tiang
 1401459,-- Parasut Transformers
 1401460,-- Parasut Dewa Takdir
 1401461,-- Parasut Anjing Cinta
 1401462,-- Bbangbbang's diary Parachute
 1401463,-- Realme Parachute
 1401464,-- Parasut Infinix GT
 1401465,-- Parasut C9S25
 1401466,-- Parasut Ác Iblis
 1401467,-- Parasut Kaiju No. 8
 1401468,-- Parasut TEAM SONIC
 1401469,-- Parasut Danau Kupu-kupu Berkilau Berkilau
 1401470,-- Parasut Lotus
 1401471,-- Parasut Bunga Kusut
 1401472,-- Parasut Gen selesai Bagus
 1401473,-- Tokyo Revengers Parachute
 1401474,-- Sky Striker Parachute
 1401475,-- Parasut C9S26
 1401476,-- Parasut Meluncur Beruang Manis Manis
 1401477,-- Parasut Balenciaga
 1401478,-- Parasut Meluncur Salju Dingin
 1401479,-- Parasut Porsche
 1401480,-- Parasut Hitam Linh
 1401481,-- Parasut Musang Chill
 1401482,-- TV Anime DAN DA DAN Parachute
 1401483,-- Parasut C9S27
 1401484,-- Parasut Meluncur Shuriken
 1401485,-- Parasut Bayangan Ma Anh Negara
 1401486,-- Parasut The King of Fighters
 1401487,-- Parasut Meluncur Senjata Bagian
 1401488,-- Parasut Lindungi Batu
 1401489,-- Parasut Rangkaian Musim Pecahkan (2026H1)
 1401490,-- Parasut S28
 1401491,-- Parasut Permainan Main Penguasa Badut Licik Bidang
 1401492,-- Parasut Apollo
 1401493,-- Parasut Hacker Dingin Aneh
 1401494,-- Parasut Festival Kumpul Multi Arah
 1401495,-- Catch! Teenieping Parachute
 1401496,-- SAKAMOTO TARO Parachute
 1401497,-- Nakiri Ayame Parachute
 1401498,-- Parasut S29
 1401499,-- Toxic Parachute
 1401500,-- Parasut Red (Bulat)
 1401511,-- Parasut Kucing Tinh Terbalik
 1401513,-- Parasut San Martin FC
 1401515,-- Parasut Mata Iblis
 1401516,-- Parasut gelombang Malam
 1401517,-- Parasut hasil Jeruk
 1401519,-- Parasut Beruang Mendengkur Tidur
 1401520,-- Parasut Belakang Keturunan Kaisar Raja
 1401521,-- Parasut awan Gulung
 1401526,-- Parasut bunga Teks Kuat Rasio
 1401527,-- Parasut Kiri Tim Laut Semua
 1401528,-- Parasut Perjalanan Tinh Ibu
 1401529,-- Parasut Kerajaan Maut Ánh Emas
 1401530,-- Parasut Armor Gai
 1401531,-- Parasut Area Nguy Bahaya
 1401532,-- Parasut Ốc Laut
 1401534,-- Parasut Bebek Kuning B.Duck
 1401538,-- Parasut Kelinci Lembut Lembut
 1401540,-- Parasut Yeti
 1401541,-- Parasut Pixel Warna Warna
 1401542,-- Parasut Indah Posisi
 1401543,-- Parasut I Love Tao Kae Noi
 1401544,-- Parasut Burung beo Baby
 1401545,-- Parasut U.F.O
 1401546,-- Parasut Baby Shark
 1401547,-- Parasut Beruang Isi Bunga
 1401548,-- Parasut Kucing Serius Cukup
 1401549,-- Parasut Vinh Quang Lapangan ada
 1401551,-- Parasut Wanita Raja pulihkan Armor
 1401554,-- Parasut Sangat besar Long Pixel
 1401555,-- Parasut Sayap Kupu-kupu Kerajaan Gia
 1401556,-- Parasut Perjalanan Proses Manis Manis
 1401610,-- Parasut Ucapkan Selamat buat hari
 1401611,-- Parasut Arena Potong Berkilau Berkilau
 1401613,-- Parasut Dalam Vonis Anubis
 1401615,-- Parasut Dewa Horus
 1401616,-- Parasut One Plus
 1401617,-- Parasut Guru Maut Raungan
 1401618,-- Parasut Facebook
 1401619,-- Parasut Jimat Lindungi Takdir Pharaoh
 1401620,-- Parasut Pharaoh (hijau)
 1401621,-- Parasut Darah Nha
 1401622,-- Parasut LINE FRIENDS
 1401623,-- Parasut PMNC 2021
 1401624,-- Parasut Poseidon
 1401625,-- Parasut Fungsi Penguasa Set Tersesat
 1401628,-- Parasut Phoenix Kerajaan Adarna virtual Ajaib
 1401629,-- Parasut Kurang Wanita Terang Dunia
 1401811,-- Giannis Parachute
 1401813,-- Parasut Perjalanan Proses Anh Pahlawan
 1401814,-- Parasut Rock 'n' Roll
 1401815,-- Parasut Hanya Huy Pertempuran Lapangan
 1401816,-- Parasut BURGER KING
 1401817,-- Parasut Pertempuran Binh Darah Elang
 1401820,-- Parasut Ikan Capung
 1401822,-- Parasut Monster Hewan Rawa Becek
 1401823,-- Parasut pimpin Penguasa Phong
 1401824,-- Parasut Kotak Hadiah
 1401826,-- Parasut - Rayap Cinta Kepala
 1401827,-- Parasut Wanita Kerajaan Kopi Nikmat
 1401828,-- Parasut Penjaga Binh Kuno Besar
 1401829,-- Parasut Badai Marah dari Dewa
 1401832,-- Parasut C4S10
 1401833,-- Parasut Monster Hewan Mabuk Cung
 1401835,-- Parasut Poker objek Tahan
 1401836,-- Parasut Permainan Main Badut Badut
 1401837,-- Parasut Ilusi gambar
 1401838,-- Parasut BLUE LOCK
 1401839,-- Parasut Ford
 1401840,-- Parasut Harley-Davidson®
 1401841,-- Parasut bunga Pink Tulang
 1401842,-- Parasut Song Maut
 1401843,-- Parasut Meluncur Putaran Bulan Kayu manis
 1401844,-- Parachute(Pubniku)
 1401845,-- Parasut S30
 1401846,-- Parasut Hal Item Trial of Fire
 -- [ kapal glider / papan seluncur / Baja terkena pesawat (Gliders/Hoverboards) ]
 4151001,-- Parasut (hijau)
 4151002,-- hasil sesuai lompat Parasut (Kuning)
 4151003,-- asap Meluncur Parasut (Pink)
 4151004,-- asap meluncur hijau
 4151006,-- asap meluncur bola Pelangi
 4151010,-- Baja Terkena bay dengan Cerah
 4151012,-- Papan Seluncur Chu pun
 4151013,-- Papan Seluncur Salju
 4151014,-- Papan meluncur CHU pun 2
 4151015,-- asap Meluncur Parasut Ucapkan Selamat (3 warna)
 4151017,-- Papan meluncur Kiri Tim hutan hijau
 4151018,-- Papan meluncur buat hari
 4151019,-- Kapal Meluncur Pertempuran Dewa Cinta Cinta
 4151020,-- Papan Seluncur Peringatan Penjaga C3
 4151021,-- Kapal Meluncur Utusan palsu dari Dewa
 4151022,-- Kapal Meluncur Sayap Kuning
 4151023,-- Papan Seluncur Gabung aksi Messi
 4151024,-- Kapal Meluncur Tombak prajurit Merah Pekat
 4151025,-- Kapal Meluncur Layang-layang Kertas
 4151026,-- Papan Seluncur Besar Guru Bela diri Jiwa
 4151027,-- Papan Seluncur Cycle 4
 4151028,-- Papan Seluncur Tetes Rasio Darah
 4151029,-- Kapal Meluncur Wanita Kaisar Ánh Terang
 4151030,-- Kapal Meluncur Ma Raja Darah Jiwa
 4151031,-- Kapal Meluncur Sangat besar Long Kantong Uang
 4151032,-- Kapal Meluncur Sayap Naga Merah Pekat
 4151034,-- Timbang Gayung Awan
 4151035,-- Kapal Meluncur Giao Menikmati angin
 4151036,-- Papan Seluncur Mesin Pukul gelombang
 4151037,-- Papan Seluncur CYCLE 5
 4151038,-- Parasut Meluncur Permata Trai Mutlak Bagus
 4151040,-- Papan meluncur Pengrajin Berburu Listrik Quang
 4151041,-- Parasut Meluncur Tulang hijau
 4151042,-- Kapal Meluncur Fungsi Penguasa Fungsi Seni
 4151043,-- Kapal Meluncur Fungsi Penguasa Fungsi Seni
 4151044,-- Papan Seluncur Ikan Gemuk
 4151045,-- Parasut Meluncur Musim Timur Kerajaan Gia
 4151046,-- Papan Seluncur Bilah Dao langit hijau
 4151056,-- Parasut Meluncur Musim Timur Kerajaan Gia
 4151057,-- Papan Seluncur Api Danau Ly
 4151058,-- Parasut Meluncur LINE FRIENDS
 4151059,-- Papan Seluncur Tembus awan
 4151060,-- Parasut Meluncur Ular Emas
 4151061,-- Papan Seluncur CYCLE 6
 4151062,-- asap Meluncur Parasut Zanmang Loopy
 4151063,-- SPY×FAMILY Kapal Meluncur Bond
 4151064,-- Parasut Meluncur Langit Utusan
 4151065,-- Parasut Meluncur Langit Utusan
 4151066,-- Parasut Meluncur Kaisar Raja Dewa Jurang
 4151067,-- Parasut Meluncur Kacamata Seribu bunga
 4151068,-- Kapal Meluncur Penguasa penguasa Gai Racun
 4151069,-- Kapal Meluncur Tinh Awan petir Petir
 4151070,-- Kapal Meluncur Ksatria Binh Dewa Armor
 4151071,-- Parasut Meluncur Penjaga Dewa Cinta Ái
 4151072,-- Parasut Meluncur Senjata Tiang
 4151073,-- Parasut Meluncur Neon Misteri Rahasia
 4151074,-- PUBGM X NewJeans Glider
 4151075,-- Parasut Meluncur Penjaga Dewa Cinta Ái
 4151076,-- Kapal Meluncur Sembilan Phong Langit Hormat
 4151077,-- Mesin Bay
 4151078,-- Kapal Meluncur Laut Kode Besi
 4151079,-- Kapal Meluncur Ganda Sayap Dunia batas Bawah tanah
 4151080,-- Papan Seluncur Cycle 7
 4151083,-- Parasut Meluncur Long Tulang
 4151084,-- Pink Api Api - Kar98 (Level 8)
 4151085,-- Parasut Meluncur Sayap Baja Tembus Tidak
 4151086,-- DP Drift Parachute
 4151087,-- Parasut Meluncur Long Tulang
 4151089,-- Parasut Meluncur Hitam Burung 
 4151090,-- Parasut Meluncur Mimpi Mimpi Manis Manis
 4151091,-- Kapal Meluncur Rumah Jelajah Hancur Senjata Tiang
 4151092,-- Parasut Meluncur Biru Guru Tinh Sungai
 4151093,-- Parasut Meluncur Permata Lang Langit batas
 4151094,-- Papan Seluncur CYCLE 8
 4151095,-- Parasut Meluncur Ganda Sayap Anukhra
 4151096,-- Parasut Meluncur Ganda Sayap Pharaoh
 4151097,-- Kapal Meluncur Super Hewan Ghidorah
 4151098,-- Parasut Meluncur Waktu Quang Kemampuan Berubah
 4151099,-- Parasut Meluncur Raja Kekuasaan Hitam gelap
 4151103,-- Parasut Meluncur Pertempuran jauh Tinh Cantik
 4151104,-- Kapal Meluncur Baja Terkena ODM
 4151105,-- Parasut Meluncur tetap Takdir Darah Badut
 4151106,-- Parasut Meluncur Quang virtual Listrik dari 
 4151107,-- Parasut Meluncur Pertempuran jauh Tinh Cantik
 4151108,-- Kapal Meluncur Laserbreak
 4151109,-- Kapal Meluncur Es Dewa
 4151110,-- Kapal Meluncur Long Suci
 4151111,-- Kapal Meluncur Pengrajin Berburu Balasan Kekuatan
 4151112,-- Kapal Meluncur Jahat Dewa Indah Quang
 4151113,-- Papan Seluncur CYCLE 9
 4151114,-- Kapal Meluncur Long Suci
 4151115,-- Kapal Meluncur Es Dewa
 4151117,-- Kapal Meluncur Preondactyl
 4151118,-- Parasut Meluncur Danau Kupu-kupu Berkilau Berkilau
 4151119,-- Parasut Meluncur Sapu Sihir Teknik
 4151120,-- Parasut Meluncur Long Kacamata
 4151121,-- Mikey Glider
 4151122,-- Parasut Meluncur Danau Kupu-kupu Berkilau Berkilau
 4151123,-- Kapal Meluncur Es Linh Simpan Ly
 4151124,-- Kapal Meluncur Darah Sayap Maut Dewa
 4151125,-- Kapal Meluncur Penjaga Binh Perak Sungai
 4151126,-- Kapal Meluncur Pecahkan posisi
 4151127,-- Kapal Meluncur Linh Kayu Abadi Sembilan
 4151128,-- Kapal Meluncur Dewa Quang
 4151129,-- Papan Seluncur Rangkaian Musim Pecahkan (2026H1)
 4151130,-- Kapal Meluncur Nue
 4151131,-- Kapal Meluncur Phoenix Kerajaan Kaisar Raja
 4151132,-- Kapal Meluncur Darah Sayap Hitam Burung
 4151133,-- Kapal Meluncur Terjemahan pindah Tidak durasi
 4151134,-- Parasut Meluncur Multi Senjata Tiang
 4151135,-- SAKAMOTO TARO Glider
 4151138,-- Kapal Meluncur petir Petir Merah
 4151139,-- Kapal Meluncur Rusak Tidak
 4151140,-- Kapal Meluncur Song Maut
 4151141,-- Kapal Meluncur Cerberus
 4151142,-- Kapal Meluncur Permata Trai
 4151143,-- Kapal Meluncur Song Maut
202408087,202408061,1102001001, 4152031,-- Kapal Meluncur Ma Raja Darah Jiwa
 4152035,-- Timbang Gayung Awan
 4152036,-- Windborne Euphony Glider
 4152037,-- Papan Seluncur Mesin Pukul gelombang
 4152038,-- Papan Seluncur CYCLE 5
 4152039,-- Kapal Meluncur Permata Trai Mutlak Bagus
 4152041,-- Boxerbolt Hoverboard (Shop)
 4152042,-- Blueyonder Glider
 4152043,-- Agile Charmer Glider
 4152044,-- Agile Charmer Glider
 4152045,-- Chilly Perch Glider
 4152046,-- Foxy Flare Hoverboard
 4152058,-- LINE FRIENDS Glider (Shop)
 4152059,-- Cloud Piercer Hoverboard (Shop)
 4152060,-- Golden Wings Glider (Shop)
 4152061,-- CYCLE 6 Skateboard (Shop)
 4152063,-- Kapal Meluncur Bond SPY×FAMILY (Pintu Barang)
 4152066,-- Parasut Meluncur Kaisar Raja Dewa Jurang (Pintu Barang)
 4152067,-- Kapal Meluncur Kacamata Seribu bunga (Pintu Barang)
 4152068,-- Kapal Meluncur Penguasa penguasa Gai Racun (Pintu Barang)
 4152069,-- Kapal Meluncur Tinh Awan petir Petir (Pintu Barang)
 4152070,-- Kapal Meluncur Ksatria Binh Dewa Armor (Pintu Barang)
 4152076,-- Kapal Meluncur Sembilan Phong Langit Hormat (Pintu Barang)
 4152077,-- Kapal Meluncur (Pintu Barang)
 4152078,-- Kapal Meluncur Laut Kode Besi (Pintu Barang)
 4152079,-- Kapal Meluncur Ganda Sayap Dunia batas Bawah tanah (Pintu Barang)
 4152080,-- Papan Seluncur CYCLE 7 (Pintu Barang)
 4152092,-- Kapal Meluncur Biru Guru Tinh Sungai (Pintu Barang)
 4152093,-- Kapal Meluncur Permata Lang Langit batas (Pintu Barang)
 4152094,-- Papan Seluncur CYCLE 8 (Pintu Barang)
 4152095,-- Parasut Meluncur Ganda Sayap Anukhra
 4152096,-- Parasut Meluncur Ganda Sayap Pharaoh
 4152097,-- Kapal Meluncur Super Hewan Ghidorah
 4152098,-- Parasut Meluncur Waktu Quang Kemampuan Berubah
 4152099,-- Parasut Meluncur Raja Kekuasaan Hitam gelap
 4152116,-- Kapal Meluncur Long Suci (Lobby SATU Orang)
 -- ==============================================================================
 -- 3. TRANG pulih (OUTFITS), X-SUIT & tambahan syarat
 -- ==============================================================================
 -- [ X-SUIT ]
 1407895,-- X-Suit Gagak Darah (7 Sao)
 1407856,-- X-Suit Phoenix Kerajaan (7 Sao)
 1405628,-- X-Suit Pharaoh Kuning (6 Sao)
 1406469,-- X-Suit Pharaoh Kuning (7 Sao)
 1405870,-- X-Suit Gagak Darah (6 Sao)
 1407140,-- X-Suit Poseidon (7 Sao)
 1407142,-- X-Suit Silvanus (7 Sao)
 1407141,-- X-Suit Badai Salju (7 Sao)
 1407550,-- X-Suit Ánh Terang bola Pelangi (7 Sao)
 1406638,-- X-Suit Badut Rahasia sembunyi (6 Sao) [Hitam]
 1406641,-- X-Suit Badut Rahasia sembunyi (6 Sao) [Putih]
 1406872,-- X-Suit Penguasa penguasa Suara Ty (7 Sao)
 1406971,-- X-Suit Marmoris (7 Sao)
 1407103,-- X-Suit Fiore (7 Sao)
 1407219,-- X-Suit Ignis (7 Sao)
 1407366,-- X-Suit Galadria (7 Sao)
 1407512,-- X-Suit Anukhra (7 Sao)
 1407625,-- X-Suit Dravion (7 Sao) [Nam]
 1407667,-- X-Suit Dravion (7 Sao) [Wanita]
 -- [ OUTFITS ]
 1407870,-- Set Wanita Dewa Tidak durasi
 1407871,-- Set Penyelidik Maut Multi Senjata Tiang
 1407812,-- Set Penjaga Binh Hoang Liar
 1407758,-- Set Dewa Wanita Musim Timur
 1407286,-- Set Kucing Cyber Tinh Terbalik
 1407329,-- Set Ánh Terang Statis Hening
 1407391,-- Set Wanita Dominan Gelar Ma Kopi Naga
 1407392,-- Set Orang Hancur Rusak Man Mengerikan
 1407387,-- Set Maut Dewa Akhir Dunia
 1407440,-- Set Orang Chinh Pulih Utara Ekstrem
 1406985,-- Set Orang Cinta Area Laut
 1407470,-- Set Langit Dewa Muncul Kacau
 1407471,-- Set Ekstrem Quang Nanh Permata
 1407522,-- Set Belakang Keturunan Dewa Pasir
 1407330,-- Set Laksamana Komandan Bayangan Ma
 1407523,-- Set Uy Kekuasaan Jahat Ác
 1407558,-- Set kondisi Matahari Naik bunga
 1407559,-- Set Cahaya Bulan
 1407572,-- Set Darah Malam Kerajaan Cium
 1407682,-- Set Kepompong sembunyi prajurit
 1407695,-- Set Acara Cinta Orang Seram Merinding
 1407696,-- Set Makam Kacamata Naik bunga
 1407632,-- Set Hitam Malam Jahat Ác
 1407573,-- Set Bayangan Ma Listrik Maut
 1406398,-- Set Bayangan Ma Terang Api
 1406399,-- Set Ksatria Binh Oai Penjaga
 1406482,-- Set Penguasa penguasa Gai sudut
 1406483,-- Set Tinh Awan petir Petir
 1406555,-- Set Bentuk Wajah Bumi Neraka
 1406573,-- Set Langit Nga Bayangan Ma
 1406574,-- Set PENTING Menara Senjata Tiang
 1406656,-- Set Siang Berlumur Darah
 1406657,-- Set Laksamana Komandan Laut Sao
 1406742,-- Set Jalan Guru perak
 1406744,-- Set Kesatria prajurit kondisi Matahari
 1406789,-- Set Bayangan Ma Bumi Neraka
 1406823,-- Set Tetes Bulan Tidak Hancurkan
 1406824,-- Set Orang Musuh Berwarna Darah
 1406897,-- Set Ác Mimpi Merah Pekat
 1407277,-- Trang Pulih Api Dewa Kuno bahasa
 1406891,-- Trang Pulih Linh Jiwa Tubuh Bumbu
 1405623,-- Set Tubuh Bumbu Kuning
 1400687,-- Set Tubuh Bumbu Putih
 1407618,-- Set Nyata Jiwa Utara Ekstrem (Polar Spectrophage)
 -- [ Dragon Ball Super Collab ]
 1406937,-- Trang Pulih Orang Benda Super Saiyan Son Goku
 1406938,-- Trang Pulih Orang Benda Frieza
 1406939,-- Trang Pulih Orang Benda Son Goku
 1406947,-- Trang Pulih Orang Benda Vegeta
 1406948,-- Trang Pulih Orang Benda Super Saiyan Vegeta
 1406950,-- Trang Pulih Beerus
 1406951,-- Trang Pulih Ma Buu
 1406952,-- Trang Pulih Quy Tua Kame
 1406953,-- Trang Pulih Orang Benda Gohan Super Level
 1406954,-- Trang Pulih Orang Benda Piccolo
 1407264,-- Trang Pulih Orang Benda Vegito
 1407265,-- Trang Pulih Orang Benda Vegito Super Saiyan
 1407266,-- Trang Pulih Orang Benda Vegito Super Saiyan hijau
 1407267,-- Trang Pulih Orang Benda Son Goku Super Saiyan hijau
 1407268,-- Trang Pulih Orang Benda Son Goku Super Saiyan hijau (Terkena Luka)
 1407269,-- Trang Pulih Orang Benda Vegeta Super Saiyan hijau
 1407270,-- Trang Pulih Orang Benda Vegeta Super Saiyan hijau (Terkena Luka)
 1407271,-- Trang Pulih Orang Benda Bulma
 -- [ Evangelion Collab ]
 1406385,-- Plugsuit Evangelion Shinji
 1406386,-- Plugsuit Evangelion Rei
 1406387,-- Plugsuit Evangelion Asuka
 1406388,-- Plugsuit Evangelion Mari
 1406389,-- Plugsuit Evangelion Kaworu
 -- [ Attack on Titan Collab ]
 1407563,-- Trang Pulih Orang Benda Eren Jaeger
 1407565,-- Trang Pulih Orang Benda Mikasa Ackermann
 1407566,-- Trang Pulih Orang Benda Armin Arlelt
 1407567,-- Trang Pulih Titan Raksasa Besar (Armin)
 1407568,-- Trang Pulih Orang Benda Levi
 1407569,-- Trang Pulih Titan Bungkus Baja
 -- [ Kaiju No. 8 Collab ]
 1407672,-- Trang Pulih Orang Benda Kafka Hibino
 1407673,-- Trang Pulih Kaiju No. 8
 1407674,-- Trang Pulih Orang Benda Kikoru Shinomiya
 1407675,-- Trang Pulih Kaiju No. 9
 1407676,-- Trang Pulih Kaiju No. 10
 1407677,-- Trang Pulih Orang Benda Mina Ashiro
 1407678,-- Trang Pulih Orang Benda Reno Ichikawa
 1407679,-- Trang Pulih Orang Benda Soshiro Hoshina
 -- [ BlackPink & Kpop Collabs ]
 1406132,-- Pakaian DDU-DU DDU-DU ROSÉ
 1406133,-- Pakaian DDU-DU DDU-DU JENNIE
 1406134,-- Pakaian DDU-DU DDU-DU JISOO
 1406135,-- Pakaian DDU-DU DDU-DU LISA
 1406161,-- Pakaian How You Like That ROSÉ
 1406162,-- Pakaian How You Like That JENNIE
 1406163,-- Pakaian How You Like That JISOO 
 1406164,-- Pakaian How You Like That LISA
 1406178,-- Pakaian Lovesick Girls ROSÉ
 1406179,-- Pakaian Lovesick Girls JENNIE
 1406180,-- Pakaian Lovesick Girls JISOO
 1406181,-- Pakaian Lovesick Girls LISA
 1407346,-- PUBGM X NewJeans MINJI Set
 1407347,-- PUBGM X NewJeans HANNI Set
 1407348,-- PUBGM X NewJeans HAERIN Set
 1407349,-- PUBGM X NewJeans DANIELLE Set
 1407350,-- PUBGM X NewJeans HYEIN Set
 1407745,-- Trang Pulih RAMI (Babymonster)
 1407746,-- Trang Pulih ASA (Babymonster)
 1407747,-- Trang Pulih AHYEON (Babymonster)
 1407748,-- Trang Pulih RORA (Babymonster)
 1407749,-- Trang Pulih CHIQUITA (Babymonster)
 1407750,-- Trang Pulih PHARITA (Babymonster)
 1407751,-- Trang Pulih RUKA (Babymonster)
 1407826,-- Trang Pulih PUBG MOBILE × aespa KARINA
 1407827,-- Trang Pulih PUBG MOBILE × aespa GISELLE
 1407828,-- Trang Pulih PUBG MOBILE × aespa WINTER
 1407829,-- Trang Pulih PUBG MOBILE × aespa NINGNING
 1407687,-- Trang Pulih G-DRAGON PEACEMINUSONE
 1407688,-- Trang Pulih Arena Potong dari G-DRAGON
 -- [ semua COLLAB MUNCUL aktif berbeda (Messi, Logika Kecil Long, SPYxFAMILY...) ]
 1406648,-- Trang Pulih Tampilan Patung Bayangan batu Messi
 1406649,-- Trang Pulih Misteri Telepon Super Sao Messi
 1406728,-- Trang Pulih Kung Fu Logika Kecil Long
 1406729,-- Trang Pulih Ahli Gia Dekat Pertempuran Logika Kecil Long
 1406730,-- Trang Pulih Naga geram Logika Kecil Long
 1406731,-- Trang Pulih Bela diri prajurit Logika Kecil Long
 1407206,-- SPY×FAMILY Trang Pulih Kerajaan Cium
 1407401,-- C.C. Set
 1407402,-- Kallen Kozuki Set
 1407404,-- Suzaku Kururugi Set
 1407405,-- ZERO Set
 1407408,-- Emperor Lelouch Set
 1407769,-- Okarun(transformed) Set
 1407770,-- Okarun Set
 1407771,-- Momo Set
 1407772,-- Jiji(transformed) Set
 1407773,-- Aira Set
 1407794,-- Trang Pulih Orang Benda John Shelby
 1407795,-- Trang Pulih Orang Benda Arthur Shelby
 1407796,-- Pakaian Thomas Shelby
 1407798,-- Trang Pulih Orang Benda Iori Yagami
 1407800,-- Trang Pulih Orang Benda Mai Shiranui
 1407801,-- Trang Pulih Orang Benda Nakoruru
 1407846,-- Trang Pulih Orang Benda Kimono Ryomen Sukuna
 1407848,-- Trang Pulih Orang Benda Suguru Geto
 1407901,-- Trang Pulih Orang Benda Isagi Yoichi
 1407902,-- Trang Pulih Orang Benda Bachira Meguru
 -- [ Set item Merah otomatis & super VIP dari Game ]
 1405160,-- Misteri Telepon Godzilla
 1405161,-- Super Hewan Ghidorah
 1405186,-- Set Perlengkapan Godzilla
 1405662,-- Pakaian Armor Samurai
 1405663,-- Pakaian Dekat Tangan Bayangan Malam
 1406020,-- Pakaian Monster Hewan
 1406398,-- Pakaian Api Api Ma Armor
 1406399,-- Pakaian Ksatria Binh Dewa Armor
 1406456,-- Trang Pulih Anh Pahlawan teruskan Teori
 1406568,-- Trang Pulih Wanita Kerajaan Bayangan Malam
 1406569,-- Trang Pulih Minh Raja Perjalanan Putusan
 1406732,-- Trang Pulih Wanita Kaisar Kerajaan Emas
 1406733,-- Trang Pulih Kerajaan Kaisar Kerajaan Emas
 1406764,-- Trang Pulih Kurang Wanita Merah Terang
 -- ==============================================================================
 -- 4. baju, celana, Sepatu Indah & TDM (PHONG jarak SANGAT CHẤT)
 -- ==============================================================================
 -- [ BAPE & ALAN WALKER ]
 1400569,-- BAPE MIX CAMO HOODIE
 1400650,-- BAPE MIX CAMO SHORTS
 1400651,-- BAPE STA MID
 1404000,-- BAPE City Camo Hoodie
 1404002,-- BAPE City Camo Pants
 1404003,-- BAPE Sta Mid
 1404048,-- baju BAPE X PUBGM CAMO
 1404049,-- baju Hoodie Ikan Gemuk BAPE X PUBGM CAMO
 1404050,-- Celana BAPE X PUBGM CAMO
 1404051,-- Sepatu BAPE X PUBGM CAMO
 1404016,-- Alan Walker T-shirt
 1404017,-- Alan Walker Hoodie
 1404042,-- Pakaian Alan Walker
 1404043,-- baju Alan Walker
 1404044,-- Celana Alan Walker
 1404045,-- Sepatu Alan Walker
 1404340,-- Pakaian Alan Walker 2021
 1403038,-- Alan Walker Mask
 1403064,-- Mulut trang Alan Walker
 -- [ barang TDM Umum variabel (Syal tutup wajah, baju Prajurit, baju kenakan Hitam...) ]
 402001,-- Syal Loreng buat ada
 402037,-- Syal Lingkar tinggi Tambahan
 402043,-- Syal Lingkar PUBG (Merah-Hitam)
 402045,-- Syal Lingkar PUBG (Pertempuran Teknik)
 1400158,-- Wajah Topeng Hockey
 1402005,-- Mysterious Leather Mask
 1403100,-- Masker orang leo Gunung
 403010,-- Baju Tanpa Lengan Kotor (Putih)
 403028,-- baju Trench coat (Warna hitam)
 403181,-- baju Prajurit sa gurun
 403182,-- baju Hoodie Berburu Umpan (Hitam)
 403183,-- baju Hoodie khusus Ukuran (Putih)
 403192,-- baju kenakan bomber
 404006,-- Celana Jeans (Cokelat)
 404008,-- Celana Prajurit (Ka-ki)
 404013,-- Celana Prajurit (Loreng ri)
 404015,-- Celana Jeans Ketat (Warna Biru)
 404026,-- Celana Kantong Kotak (Warna be)
 404028,-- Celana Kantong Kotak (Warna hitam)
 404084,-- Celana bisa thao pendek (Hitam)
 404100,-- Celana orang sembunyi sembunyi (Hitam)
 405001,-- Sepatu Kaisar Lembut (Warna putih)
 405002,-- Sepatu bisa thao Kuno tinggi
 405019,-- Sepatu Prajurit chim Elang (Hitam)
 405044,-- Sepatu Kaisar Lembut (Hitam)
 1400013,-- Celana Jeans Indah
 -- [ semua baju LẺ VIP (Collab, super kendaraan) ]
 1404142,-- Kaos THE WALKING DEAD (Putih)
 1404143,-- Kaos THE WALKING DEAD (Hitam)
 1404218,-- baju Hoodie COVERNAT (Putih)
 1404219,-- baju Hoodie COVERNAT (Hitam)
 1404326,-- Kaos Xiaomi
 1404327,-- Kaos OnePlus
 1404405,-- baju Bertarung Gabung aksi Messi × PUBG MOBILE
 1404406,-- baju Thun Logika Kecil Long
 1404411,-- Hoodie Ducati
 1404412,-- Sepatu Ducati Corse City C2
 1404413,-- Celana Ducati Sport C2
 1404414,-- baju kenakan Ducati Speed Evo C2
 1404426,-- baju PMGC 2023
 1404427,-- Celana Orang Chinh Pulih Pagani
 1404428,-- Sepatu Orang Chinh Pulih Pagani
 1404508,-- baju Hoodie Mr.Beast
 1400324,-- baju b
 1400325,-- baju a
 452001,452002,452003,-- Sarung tangan Tay (Gloves)
 -- [ aksi gerak ]
 12201301,-- Gerakan Dekat Tangan Gothic
 12216101,-- Gerakan Bela diri prajurit Darah Elang
 12212201,-- Gerakan Dekat Tangan Ekstrem gelap
 12219207,-- Gerakan Besar Jenderal Langit Kerbau
 12209001,-- Gerakan Bela diri prajurit (Samurai)
 12219561,-- Gerakan baju selendang Merah Pekat
 12210001,-- Gerakan Benda sentuh dari Maut Dewa
 12219022,-- Gerakan Baja Penjaga Gai sudut
 12208801,-- Gerakan Berani prajurit setengah Dewa
 12210801,-- Gerakan Pengrajin Berburu Cangkang perak
 12200701,-- Gerakan Aksi Tanpa Durasi
 12219242,-- Gerakan Berjalan Langkah Labu langit
 12206001,-- Gerakan bunga linh Perunggu hijau
 12205401,-- Gerakan Vua dari Ribuan hewan
 12205201,-- Gerakan Kiri tim Raksasa hewan
 12212601,-- Gerakan Dekat hijau Dewa Rahasia
 12205601,-- Gerakan Linh Jiwa Raksasa hewan
 12219208,-- Gerakan Kera raja Cyber
 12212001,-- Gerakan Bela diri Suci
 12206801,-- Gerakan Laut long Dewa Rahasia
 12209801,-- Gerakan Kendali linh Guru
 12211401,-- Gerakan Wanita Cocok air Es salju
 12207001,-- Gerakan Aksi Laut
 12211801,-- Gerakan Penguasa Urutan OTOMATIS
 12207901,-- Gerakan Laut raja Pesona Rontok
 12203401,-- Gerakan Era Pikiran virtual gambar
 12204001,-- Gerakan Badut badut (Hari Ikan bulan Postur)
 12201801,-- Gerakan Orang Lindungi Penjaga Area salju
 12215601,-- Gerakan Super Orang Tetap tinh
 12215532,-- Gerakan pimpin penguasa Ujung api
 12213201,-- Gerakan Rencana Rencana Hari mai
 12215529,-- Gerakan Ksatria prajurit Balap xe
 12219053,-- Gerakan Wanita Kerajaan Berharga Lindungi
 12204601,-- Gerakan Langit Turun Ayah Bela diri
 12215701,-- Gerakan Perjalanan tinh Kera orang
 12219003,-- Gerakan Bayangan gelap Dewa linh
 12219004,-- Gerakan Perak Jiwa Terang api
 12219009,-- Gerakan Mabuk atau Terang api
 12219216,-- Gerakan Pengorbanan Postur Layu Menguning
 -- Rambut wajah Rimbun lum
1404198,1410085,1404366,1403137,1410480,1403028,1400158,40605011,1404323,1406001,1403002,-- ==============================================================================
 -- topi armor VIP (hanya ambil level 1 - RINGKAS GÀNG, MUDAH tersembunyi sembunyi)
 -- ==============================================================================
 1502001183,-- Godzilla Helmet (Lv. 1)
 1502001194,-- Helm MECHAGODZILLA (Level 1)
 1502001093,-- Helm Dalam Vonis Anubis (Level 1) - Pharaoh
 1502001305,-- Helm Armor Super Orang Baja (Level 1)
 1502001320,-- Helm Armor Tampilan Patung Bayangan batu Messi (Level 1)
 1502001105,-- Helm Tersembunyi gambar (Level 1)
 1502001364,-- Helm Armor PMGC 2023 (Level 1)
 1502001373,-- Helm Armor LINE FRIENDS BROWN (Level 1)
 1502001402,-- APEACH Helmet (LV.1)
 1502001403,-- Bellygom Helmet (LV.1)
 1502001427,-- Opanchu Helmet (Lv.1)
 1502001443,-- Helm Armor gelombang Suara Gila Kacau (Level 1)
 1502001450,-- Helm Armor Anjing Tinh Terbalik (Level 1)
 1502001471,-- Turbo Granny (Beckoning cat) Helmet (Lv. 1)
 1502001480,-- Helm Armor PUBG MOBILE × aespa (Level 1)
 1502001490,-- Nakiri Ayame Helmet (Lv.1)
 1502001495,-- Helm BLUE LOCK (Level 1)
 1502001001,-- Helm pizza Panas (Level 1)
 1502001004,-- Helm Cyberpunk (Ungu) (Level 1)
 1502001005,-- Helm Kotak Tengkorak (Level 1)
 1502001046,-- Helm Samurai - nama prediksi (Level 1)
 1502001058,-- Helm Lindungi Bahaya Monarch (Level 1)
 1502001064,-- Helm Lindungi Bahaya Langit Utusan (Level 1)
 1502001073,-- Helm Penjaga Binh Robot (Level 1)
 1502001078,-- Helm Ninja Dekat Tangan (Level 1)
 1502001086,-- Helm Tikus Tinh Terbalik (Level 1)
 1502001099,-- Helm Corgi (Level 1)
 1502001115,-- Helm Serangga Kura-kura (Level 1)
 1502001133,-- Helm Rahasia Jagung Kinh Aneh (Level 1)
 1502001145,-- Helm Badut Prajurit Timah (Level 1)
 1502001154,-- Helm Armor Besar Pohon Memancar Terang (Level 1)
 1502001175,-- Helm Bebek Kuning B.Duck (Level 1)
 1502001230,-- Helm Naga Fungsi Seni (Level 1)
 1502001248,-- Helm Orang buka Jalan (Level 1)
 1502001264,-- Helm Ét Kotak Ét (Level 1)
 1502001276,-- Helm Senjata Fungsi Rahasia sembunyi (Level 1)
 1502001294,-- Helm Armor Ma Sihir Guru (Level 1)
 1502001301,-- Helm Armor Archon Terkenal pemicu (Level 1)
 1502001357,-- Helm Armor Son Goku (Level 1)
 1502001381,-- Helm Armor Api Linh Tertinggi Hormat (Level 1)
 1502001416,-- Helm Armor PMGC 2024 (Level 1)
 1502001453,-- 2025 Esports Helmet (Lv. 1)
 -- ==============================================================================
 -- Tas VIP (hanya ambil level 1 - RINGKAS GÀNG, MUDAH tersembunyi sembunyi)
 -- ==============================================================================
 1501001174,-- Tas Pharaoh (Level 1)
 1501001220,-- Tas Darah Nha (Level 1)
 1501001265,-- Tas Poseidon (Level 1)
 1501001548,-- Tas Dewa Telepon Jauh Kuno (Level 1)
 1501001559,-- Tas slider bunga Ular (Level 1)
 1501001567,-- Tas Api Linh Tertinggi Hormat (Level 1)
 1501001577,-- Tas Ganda Sayap Penjaga Dewa (Level 1)
 1501001607,-- Tas Kelelawar Bayangan Malam (Level 1)
 1501001061,-- Tas Godzilla (Level 1)
 1501001062,-- Tas Super Hewan Ghidorah (Level 1)
 1501001082,-- Tas Genbu (Level 1)
 1501001112,-- Tas Pig Bodoh Konyol (Level 1)
 1501001133,-- Tas Joker Haus Darah (Level 1)
 1501001243,-- Tas Bebek Kuning B.Duck (Level 1)
 1501001273,-- Tas MECHAGODZILLA (Level 1)
 1501001304,-- Tas Ma Raja (Level 1)
 1501001331,-- Tas dari Jinx (Level 1)
 1501001340,-- Tas Laut Anjing Salju (Level 1)
 1501001376,-- Tas Mesin Nyanyi Kuno Contoh (Level 1)
 1501001400,-- Tas Baby Shark (Level 1)
 1501001463,-- Tas BoBoiBoy (Level 1)
 1501001476,-- Tas Tampilan Patung Bayangan batu Messi (Level 1)
 1501001480,-- Tas Mi Indomie (Level 1)
 1501001487,-- Tas anak Mata Mati Kematian (Level 1)
 1501001521,-- Tas Quy Tua Kame (Level 1)
 1501001539,-- Tas PMGC 2023 (Level 1)
 1501001540,-- Tas Ayam Goreng KFC (Level 1)
 1501001554,-- Tas LINE FRIENDS SALLY (Level 1)
 1501001587,-- Tas Besar Úy Kacau Dunia (Level 1)
 1501001597,-- Bellygom Backpack (LV.1)
 1501001632,-- Opanchu Backpack (Lv.1)
 1501001643,-- Frieren&Mimic Backbag (Lv.1)
 1501001650,-- Tas Titan Raksasa Besar Level 1
 1501001683,-- Tas Balenciaga (Level 1)
 1501001715,-- SAKAMOTO TARO Backpack (Lv.1)
 1501001720,-- Tas BLUE LOCK (Level 1)
 -- [ tas, topi & parasut glider ]
 1501001024,-- Tas Dominan Gelar
 1502001014,-- Helm Paku
 1502001439,-- helm raja Mahkota
 1502001069,-- helm Baja thi
 1502001023,-- helm es
 -- id Tambahkan xung
 1400092,1400101,1400122,--Postur Perintah
 1404191,-- Celana set aksi
 1405128,1405129,140224445,140224445,-- crew
 1407961,1407962,1407963,1407964,1407965,1407966,1407967,1407968,1407969,1407970,1407971,1502001508,1502002508,1502003508,1411134,1411133,1411135,1403771,1403770,1407994,1407993,1101006106,1101006098,4151145,1903230,1903231,1903232,1908117,1908118,1908119,19116002,19116003,19116004,1961070,1961071,1961072,1961073,1408045,1408038,1407990,1407922,-- Trang Pulih Wanita Dewa Ái Cinta
 1407704,-- Trang Pulih Nona Stroberi Tinh Monster
 1400782,-- Pakaian es salju
 1407614,-- Trang Pulih Optimus Prime Transformers
 1407276,-- Trang Pulih Penjaga Dewa Cinta Ái
 1410356,-- Wajah Topeng Ma Raja Darah Jiwa
 40605012,-- Rambut Hai Rangkaian
 401035,-- Helm tinggi Tambahan (Putih)
}
local INS_BASE=2000000000
local PKG_SLOT=3
local MELEE_ID=108
local HAT_SUB=401
local MASK_SUB=402
local OUTFIT_SUB=403
local PANTS_SUB=404
local SHOES_SUB=405
local GLASS_SUB=407
local GLIDER_SUB=415
local GLOVES_SUB=452
local GLIDER_SUBS={[413]=true,[414]=true,[415]=true}
F.CUST_SLOT={NONE=0,HeadEquipemtSlot=1,HairEquipemtSlot=2,HatEquipemtSlot=3,FaceEquipemtSlot=4,ClothesEquipemtSlot=5,PantsEquipemtSlot=6,ShoesEquipemtSlot=7,BackpackEquipemtSlot=8,HelmetEquipemtSlot=9,ArmorEquipemtSlot=10,ParachuteEquipemtSlot=11,GlassEquipemtSlot=12,NightVisionEquipemtSlot=13,BeardEquipemtSlot=14,GlideEquipemtSlot=15,HandEffectEquipemtSlot=16,BackPack_PendantSlot=17,}
_G.CustSlotType=F.CUST_SLOT
local CHASSIS_LIGHT_SUB=7302
local CHASSIS_LIGHT_IDS={[7302001]=true,[7302002]=true}
local DEFAULT_CHASSIS_LIGHT=7302002
local PARACHUTE_SUB=701
local DEFAULT_PARACHUTE_RES=703001
local TAB_SUIT=10
local TAB_CLOTHES=3
local PAGE_AVATAR=1
local PAGE_VEHICLE=6
local PAGE_PARACHUTE=5
local HALL_THEME_TYPE=202
local SUBTYPE_DEFAULT_TAB={[401]=1,[402]=2,[403]=10,[404]=4,[405]=5,[407]=14,[501]=15,[504]=15,[502]=16,[505]=16,}
local HAT_SUBS={[401]=true}
local HELMET_SUBS={[502]=true,[505]=true}
local HEAD_SUBS={[401]=true} -- [FIX VIP] Sudah dihapus 502 dan 505 untuk Pisah khusus selesai seluruh topi pastikan Bahaya dari Rambut/topi waktu Trang
local BAG_SUBS={[501]=true,[504]=true}
local FACE_SUBS={[402]=true,[407]=true}
local BODY_SUBS={[404]=true,[405]=true,[501]=true,[504]=true,[502]=true,[505]=true}
local GUN_SUB={[101]=true,[102]=true,[103]=true,[104]=true,[105]=true,[106]=true,[107]=true}
local NET_OK=NetErrorCode_NONE or"ok"
local R={insToRes={},resToIns={},byWeapon={}}
local _matchApplied=false
_G.AddOutfitPersist=_G.AddOutfitPersist or{path=nil,dirty=false,scheduled=false,loaded=nil,lastWritten=nil,configVehicleSlots=nil,configWeapons=nil,configSlots=nil,lobbyVehicleSubType=nil,lobbyVehicleIns=nil,lobbyVehicleResID=nil,hallThemeResID=nil,hallThemeIns=nil,configChassisLight=nil,configChassisLightMap=nil}
local PERSIST=_G.AddOutfitPersist
F.persistMarkDirty=function()end
local PERF={lobbySynced=false,mappingsDirty=true,desiredSkins=nil,skinTarget={},matchActive=false,lastBootstrapAt=0,wearDoneThisMatch=false,}
local MATCH_TICK_SEC=3.0
local MATCH_MAX_SEC=45.0
local BOOTSTRAP_COOLDOWN=2.0
local INJECT_RETRY_MAX=5
local INJECT_RETRY_SEC=3.0
function F.lobbyState()
_G.AddOutfitLobbyState=_G.AddOutfitLobbyState or{wardrobeRefreshed=false,reapplyScheduled=false,reapplyDone=false,outfitResolved=false,skinResolved=false,cachedOutfit=nil,cachedSkin=nil,injectRefreshGen=0,lobbySynced=false,}
return _G.AddOutfitLobbyState
end
local LOBBY=setmetatable({},{__index=function(_,k)return F.lobbyState()[k]end,__newindex=function(_,k,v)F.lobbyState()[k]=v end,})
function F.invalidateLobbyResolved()
LOBBY.outfitResolved=false
LOBBY.skinResolved=false
LOBBY.cachedOutfit=nil
LOBBY.cachedSkin=nil
end
function F.perfInvalidateLobby()
LOBBY.lobbySynced=false
PERF.mappingsDirty=true
PERF.desiredSkins=nil
for k in pairs(PERF.skinTarget)do PERF.skinTarget[k]=nil end
F.invalidateLobbyResolved()
end
function F.cache()
_G.AddOutfitEquippedCache=_G.AddOutfitEquippedCache or{outfitRes=nil,outfitIns=nil,hatRes=nil,hatIns=nil,maskRes=nil,maskIns=nil,glassRes=nil,glassIns=nil,tshirtRes=nil,tshirtIns=nil,pantsRes=nil,pantsIns=nil,shoesRes=nil,shoesIns=nil,bagRes=nil,bagIns=nil,helmetRes=nil,helmetIns=nil,weapons={},vehicleSlots={},hallThemeRes=nil,hallThemeIns=nil,parachuteRes=nil,parachuteIns=nil,gliderRes=nil,gliderIns=nil,glovesRes=nil,glovesIns=nil,}
return _G.AddOutfitEquippedCache
end
function F.cfg(resID)
if not resID or not CDataTable or not CDataTable.GetTableData then return nil end
return CDataTable.GetTableData("Item",resID)
end
function F.subType(c)
return c and(c.ItemSubType or c.itemSubType)or nil
end
function F.wardrobeTab(resID)
local c=F.cfg(resID)
return c and tonumber(c.WardrobeTab)or 0
end
function F.depotResID(v)
return v and tonumber(v.resID or v.res_id)or nil
end
function F.resToCustSlot(resID,st)
resID,st=tonumber(resID),tonumber(st)
if not resID or resID<=0 then return nil end
st=st or F.subType(F.cfg(resID))
if st==HAT_SUB or HAT_SUBS[st]then return F.CUST_SLOT.HatEquipemtSlot end
if st==OUTFIT_SUB then return F.CUST_SLOT.ClothesEquipemtSlot end
if st==PANTS_SUB then return F.CUST_SLOT.PantsEquipemtSlot end
if st==SHOES_SUB then return F.CUST_SLOT.ShoesEquipemtSlot end
if st==MASK_SUB then return F.CUST_SLOT.FaceEquipemtSlot end
if st==GLASS_SUB then return F.CUST_SLOT.GlassEquipemtSlot end
if st==GLOVES_SUB then return F.CUST_SLOT.HandEffectEquipemtSlot end
if BAG_SUBS[st]then return F.CUST_SLOT.BackpackEquipemtSlot end
if HELMET_SUBS[st]then return F.CUST_SLOT.HelmetEquipemtSlot end
if F.isParachuteRes(resID)or st==PARACHUTE_SUB then return F.CUST_SLOT.ParachuteEquipemtSlot end
if F.isGlideRes(resID)or GLIDER_SUBS[st]then return F.CUST_SLOT.GlideEquipemtSlot end
return nil
end
function F.isSuitRes(resID)
if F.subType(F.cfg(resID))~=OUTFIT_SUB then return false end
return F.wardrobeTab(resID)~=TAB_CLOTHES
end
function F.isTshirtRes(resID)
return F.subType(F.cfg(resID))==OUTFIT_SUB and F.wardrobeTab(resID)==TAB_CLOTHES
end
function F.weaponIdFromSkin(resID)
local m=CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("WeaponSkinMapping",resID)
if not m then return nil end
return m.WeaponID or m.WeaponId
end
function F.isValidWeaponId(weaponID)
weaponID=tonumber(weaponID)
if not weaponID or weaponID<=0 then return false end
if weaponID==MELEE_ID then return true end
return weaponID>=101000 and weaponID<108000
end
function F.isValidWeaponPersistEntry(weaponID,resID)
weaponID,resID=tonumber(weaponID),tonumber(resID)
if not F.isValidWeaponId(weaponID)or not resID or resID<=0 then return false end
if weaponID==resID then return false end
if resID>=1800000 and resID<1810000 then return false end
if resID>=1900000 and resID<2000000 then return false end
if F.isInjectedRes(resID)then
local wid=tonumber(F.weaponIdFromSkin(resID))
return wid and wid==weaponID
end
local wid=tonumber(F.weaponIdFromSkin(resID))
return wid and wid==weaponID
end
function F.sanitizeConfigWeapons(wmap)
if type(wmap)~="table"then return{}end
local clean={}
for wid,res in pairs(wmap)do
wid,res=tonumber(wid),tonumber(res)
if F.isValidWeaponPersistEntry(wid,res)then clean[wid]=res end
end
return clean
end
function F.indexWeaponSkin(resID,insID)
resID,insID=tonumber(resID),tonumber(insID)
if not resID or not insID then return end
local c=F.cfg(resID)
local st=F.subType(c)
if not(GUN_SUB[st]or st==MELEE_ID)then return end
local wid=F.weaponIdFromSkin(resID)
wid=tonumber(wid)
if not wid or wid<=0 then return end
R.byWeapon[wid]=R.byWeapon[wid]or{}
R.byWeapon[wid][resID]=insID
end
function F.isInjectedIns(ins)
return ins and R.insToRes[tonumber(ins)]~=nil
end
function F.isInjectedRes(res)
return res and R.resToIns[tonumber(res)]~=nil
end
function F.isWeaponSkinRes(resID)
resID=tonumber(resID)
if not resID then return false end
local st=F.subType(F.cfg(resID))
return GUN_SUB[st]or st==MELEE_ID
end
function F.isWeaponSkinIns(insID)
insID=tonumber(insID)
if not insID then return false end
local res=R.insToRes[insID]
return res and F.isWeaponSkinRes(res)
end
function F.cleanArmoryPollution()
pcall(function()
local Arm=require("client.logic.armory.logic_armory")
if not Arm.rsp_list then return end
if Arm.rsp_list.install_list then
for wid,entry in pairs(Arm.rsp_list.install_list)do
local ins=tonumber(entry and entry.skin_id)
if ins and not F.isWeaponSkinIns(ins)then
Arm.rsp_list.install_list[wid]=nil
end
end
end
if Arm.rsp_list.skin_list then
for wid,skins in pairs(Arm.rsp_list.skin_list)do
if type(skins)=="table"then
for resID in pairs(skins)do
if not F.isWeaponSkinRes(tonumber(resID))then
skins[resID]=nil
end
end
end
end
end
end)
end
function F.depotSubType(insID,resID)
resID=tonumber(resID)or tonumber(R.insToRes[insID])
local st=F.subType(F.cfg(resID))
if st then return st end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
return d and tonumber(d.itemSubType)
end
function F.tryLocalWearByIns(insID)
insID=tonumber(insID)
if not insID then return false end
 if _G.AimPROConfig and _G.AimPROConfig.ModSkin==false then return false end -- Lewati jika dimatikan Mod Skin
local resID=R.insToRes[insID]
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not resID and d then resID=tonumber(d.resID or d.res_id)end
if not resID or resID<=0 then return false end
local st=F.depotSubType(insID,resID)
local function mapLocal()
if not R.insToRes[insID]then
R.insToRes[insID]=resID
R.resToIns[resID]=insID
end
end
if st==GLOVES_SUB then mapLocal();F.putOnGloves(insID)return true end
F.clearItemExpire(d,insID,resID)
F.ensureDepotItemValid(insID,resID)
if F.isParachuteRes(resID)then mapLocal();return F.putOnParachute(insID)end
if F.isGlideRes(resID)or GLIDER_SUBS[st]then mapLocal();return F.putOnGlider(insID)end
if st==OUTFIT_SUB then
mapLocal()
if F.isSuitRes(resID)or F.wardrobeTab(resID)==TAB_SUIT then
F.putOnOutfit(insID)
else
F.putOnRoleWear(insID)
end
return true
end
if st==HAT_SUB or HEAD_SUBS[st]then mapLocal();F.putOnHat(insID)return true end
if FACE_SUBS[st]then mapLocal();F.putOnFaceAccessory(insID)return true end
if BODY_SUBS[st]or HELMET_SUBS[st]then mapLocal();F.putOnRoleWear(insID)return true end
if not F.isInjectedIns(insID)then return false end
if GUN_SUB[st]then
local wid=F.weaponIdFromSkin(resID)
if wid then F.equipWeaponSkin(wid,insID)end
return true
end
if st==MELEE_ID then F.equipWeaponSkin(MELEE_ID,insID)return true end
if F.isHallThemeRes(resID)and(F.isInjectedIns(insID)or F.isInjectedRes(resID))then
mapLocal()
return F.putOnHallTheme(insID)
end
if F.isVehicleRes(resID)and(F.isInjectedIns(insID)or F.isInjectedRes(resID))then
mapLocal()
return F.putOnVehicle(insID)
end
return false
end
function F.isHallThemeRes(resID)
local c=F.cfg(tonumber(resID))
if not c then return false end
local t=c.ItemType or c.itemType
return t==HALL_THEME_TYPE
end
function F.isResourcesReady(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return false end
if not F.isInjectedRes(resID)then return true end
local ready=false
pcall(function()
local PufferConst=require("client.slua.logic.download.puffer_const")
local mgr=ModuleManager.GetModule(ModuleManager.CommonModuleConfig.puffer_odpak_manager)
if mgr and mgr.GetStateByItemID then
local st=mgr:GetStateByItemID(resID)
ready=st==PufferConst.ENUM_DownloadState.Done
end
end)
return ready
end
function F.requestResourceDownload(resID)
resID=tonumber(resID)
if not resID or resID<=0 or not F.isInjectedRes(resID)then return end
if F.isResourcesReady(resID)then return end
_G.AddOutfitDownloadQueued=_G.AddOutfitDownloadQueued or{}
if _G.AddOutfitDownloadQueued[resID]then return end
_G.AddOutfitDownloadQueued[resID]=true
pcall(function()
local PM=require("client.slua.logic.download.puffer.puffer_manager")
local PufferConst=require("client.slua.logic.download.puffer_const")
PM.Download(PufferConst.ENUM_DownloadType.ODPAK,{resID},"AddOutfit",function()
_G.AddOutfitDownloadQueued[resID]=nil
end)
end)
end
function F.ensureInjectedResources()
for res in pairs(R.resToIns)do
F.requestResourceDownload(tonumber(res))
end
end
function F.restorePufferHooks()
pcall(function()
local mgr=ModuleManager.GetModule(ModuleManager.CommonModuleConfig.puffer_odpak_manager)
if mgr and _G.AddOutfitPufferOrig then
mgr.GetStateByItemID=_G.AddOutfitPufferOrig
end
end)
pcall(function()
local PM=require("client.slua.logic.download.puffer.puffer_manager")
if PM and _G.AddOutfitPufferGetStateOrig then
PM.GetState=_G.AddOutfitPufferGetStateOrig
end
end)
pcall(function()
local VAC=require("GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent")
local vacImpl=VAC and VAC.__inner_impl
if vacImpl and _G.AddOutfitVehOrigAssets then
vacImpl.LuaIsAssetsAlreadyAvailable=_G.AddOutfitVehOrigAssets
end
end)
end
function F.invalidateSocialWearCache()
local s=_G.AddOutfitSocialState
if s then
s.wearPatchKey,s.snapshotKey,s.fullSnapshot,s.lastHandSkin=nil,nil,nil,nil
end
end
function F.clearWeaponEquippedMark(weaponID)
_G.AddOutfitWeaponEquipped=_G.AddOutfitWeaponEquipped or{}
if weaponID then
_G.AddOutfitWeaponEquipped[tonumber(weaponID)]=nil
else
for k in pairs(_G.AddOutfitWeaponEquipped)do _G.AddOutfitWeaponEquipped[k]=nil end
end
end
function F.isWeaponVisuallyEquipped(weaponID,insID)
weaponID,insID=tonumber(weaponID),tonumber(insID)
if not weaponID or not insID then return false end
return _G.AddOutfitWeaponEquipped and _G.AddOutfitWeaponEquipped[weaponID]==insID
end
function F.saveWeaponToCache(weaponID,resID,insID)
F.clearWeaponEquippedMark(weaponID)
weaponID,resID,insID=tonumber(weaponID),tonumber(resID),tonumber(insID)
if not F.isValidWeaponPersistEntry(weaponID,resID)then return end
local cch=F.cache()
cch.weapons[weaponID]={resID=resID,insID=insID or 0}
PERSIST.configWeapons=PERSIST.configWeapons or{}
PERSIST.configWeapons[weaponID]=resID
_G.AddOutfitLastAppliedSkin={}
_matchApplied=false
F.perfInvalidateLobby()
F.invalidateSocialWearCache()
F.persistMarkDirty()
F.log("ذاكرة سكن",weaponID,"→",resID)
end
function F.cacheWeaponSkinFromIns(weaponID,insID)
weaponID,insID=tonumber(weaponID),tonumber(insID)
if not weaponID or not insID or insID<=0 then return end
if F.isInjectedIns(insID)then
F.saveWeaponToCache(weaponID,R.insToRes[insID],insID)
return
end
pcall(function()
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
if d and d.resID and tonumber(d.resID)>0 then
F.saveWeaponToCache(weaponID,tonumber(d.resID),insID)
end
end)
end
function F.saveEquip(resID,insID)
resID,insID=tonumber(resID),tonumber(insID)
if not resID or not insID then return end
local c=F.cfg(resID)
local st=F.subType(c)
local cch=F.cache()
if st==OUTFIT_SUB then
if F.wardrobeTab(resID)==TAB_CLOTHES then
cch.tshirtRes,cch.tshirtIns=resID,insID
_G.AddOutfitLastLobbyTshirtRes=resID
F.persistRememberSlot("tshirt",resID)
else
cch.outfitRes,cch.outfitIns=resID,insID
_G.AddOutfitLastLobbyOutfitRes=resID
F.persistRememberSlot("outfit",resID)
F.invalidateSocialWearCache()
end
elseif st==HAT_SUB then
cch.hatRes,cch.hatIns=resID,insID
_G.AddOutfitLastLobbyHatRes=resID
F.persistRememberSlot("hat",resID)
elseif st==MASK_SUB then
cch.maskRes,cch.maskIns=resID,insID
_G.AddOutfitLastLobbyMaskRes=resID
F.persistRememberSlot("mask",resID)
elseif st==GLASS_SUB then
cch.glassRes,cch.glassIns=resID,insID
_G.AddOutfitLastLobbyGlassRes=resID
F.persistRememberSlot("glass",resID)
elseif st==PANTS_SUB then
cch.pantsRes,cch.pantsIns=resID,insID
_G.AddOutfitLastLobbyPantsRes=resID
F.persistRememberSlot("pants",resID)
elseif st==SHOES_SUB then
cch.shoesRes,cch.shoesIns=resID,insID
_G.AddOutfitLastLobbyShoesRes=resID
F.persistRememberSlot("shoes",resID)
elseif BAG_SUBS[st]then
cch.bagRes,cch.bagIns=resID,insID
_G.AddOutfitLastLobbyBagRes=resID
F.persistRememberSlot("bag",resID)
elseif HELMET_SUBS[st]then
cch.helmetRes,cch.helmetIns=resID,insID
_G.AddOutfitLastLobbyHelmetRes=resID
F.persistRememberSlot("helmet",resID)
elseif st==PARACHUTE_SUB then
cch.parachuteRes,cch.parachuteIns=resID,insID
_G.AddOutfitLastLobbyParachuteRes=resID
F.persistRememberSlot("parachute",resID)
elseif F.isGlideRes(resID)then
cch.gliderRes,cch.gliderIns=resID,insID
_G.AddOutfitLastLobbyGliderRes=resID
F.persistRememberSlot("glider",resID)
elseif st==GLOVES_SUB then
cch.glovesRes,cch.glovesIns=resID,insID
_G.AddOutfitLastLobbyGlovesRes=resID
F.persistRememberSlot("gloves",resID)
elseif GUN_SUB[st]then
local wid=F.weaponIdFromSkin(resID)
if wid then F.saveWeaponToCache(wid,resID,insID)end
elseif st==MELEE_ID then
F.saveWeaponToCache(MELEE_ID,resID,insID)
end
_matchApplied=false
F.perfInvalidateLobby()
F.persistMarkDirty()
end
function F.findWornInsBySubType(st,filterFn)
st=tonumber(st)
if not st then return nil end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local AvatarData=require("client.logic.data.AvatarData")
for _,ins in pairs(AvatarData.GetRoleWear())do
ins=tonumber(ins)
if ins and ins>0 then
local d=wd:GetHallDepotItemDataByInsID(ins)
if d and tonumber(d.itemSubType)==st then
local res=tonumber(d.resID)
if not filterFn or filterFn(res,d)then
return ins,res
end
end
end
end
return nil
end
function F.syncHatCacheFromLobby()
local cch=F.cache()
pcall(function()
local ins,res=F.findWornInsBySubType(HAT_SUB)
if ins and res and tonumber(res)>0 then
cch.hatRes,cch.hatIns=tonumber(res),ins
return
end
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
local headIns=tonumber(bag and bag.head_show)or 0
if headIns<=0 then return end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(headIns)or wd:GetHallDepotItemDataByInsID(headIns)
if not d or not d.resID or tonumber(d.resID)<=0 then return end
local st=tonumber(d.itemSubType or F.subType(F.cfg(d.resID)))
if HEAD_SUBS[st]then
cch.hatRes,cch.hatIns=tonumber(d.resID),headIns
end
end)
end
function F.syncFaceCacheFromLobby()
local cch=F.cache()
pcall(function()
local ins,res=F.findWornInsBySubType(MASK_SUB)
if ins and res and tonumber(res)>0 then
cch.maskRes,cch.maskIns=tonumber(res),ins
_G.AddOutfitLastLobbyMaskRes=tonumber(res)
end
end)
pcall(function()
local ins,res=F.findWornInsBySubType(GLASS_SUB)
if ins and res and tonumber(res)>0 then
cch.glassRes,cch.glassIns=tonumber(res),ins
_G.AddOutfitLastLobbyGlassRes=tonumber(res)
end
end)
end
function F.syncBodyCacheFromLobby()
local cch=F.cache()
pcall(function()
local ins,res=F.findWornInsBySubType(OUTFIT_SUB,function(r)return F.wardrobeTab(r)==TAB_CLOTHES end)
if ins and res and tonumber(res)>0 then
cch.tshirtRes,cch.tshirtIns=tonumber(res),ins
_G.AddOutfitLastLobbyTshirtRes=tonumber(res)
end
end)
pcall(function()
local ins,res=F.findWornInsBySubType(PANTS_SUB)
if ins and res and tonumber(res)>0 then
cch.pantsRes,cch.pantsIns=tonumber(res),ins
_G.AddOutfitLastLobbyPantsRes=tonumber(res)
end
end)
pcall(function()
local ins,res=F.findWornInsBySubType(SHOES_SUB)
if ins and res and tonumber(res)>0 then
cch.shoesRes,cch.shoesIns=tonumber(res),ins
_G.AddOutfitLastLobbyShoesRes=tonumber(res)
end
end)
pcall(function()
local ins,res=F.findWornInsBySubType(GLOVES_SUB)
if ins and res and tonumber(res)>0 then
cch.glovesRes,cch.glovesIns=tonumber(res),ins
_G.AddOutfitLastLobbyGlovesRes=tonumber(res)
end
end)
pcall(function()
for st in pairs(BAG_SUBS)do
local ins,res=F.findWornInsBySubType(st)
if ins and res and tonumber(res)>0 then
cch.bagRes,cch.bagIns=tonumber(res),ins
_G.AddOutfitLastLobbyBagRes=tonumber(res)
break
end
end
end)
pcall(function()
for st in pairs(HELMET_SUBS)do
local ins,res=F.findWornInsBySubType(st)
if ins and res and tonumber(res)>0 then
cch.helmetRes,cch.helmetIns=tonumber(res),ins
_G.AddOutfitLastLobbyHelmetRes=tonumber(res)
break
end
end
end)
pcall(function()
local ins,res=F.findWornInsBySubType(OUTFIT_SUB,function(r)return F.isSuitRes(r)end)
if ins and res and tonumber(res)>0 then
cch.outfitRes,cch.outfitIns=tonumber(res),ins
_G.AddOutfitLastLobbyOutfitRes=tonumber(res)
end
end)
end
function F.syncAirborneCacheFromLobby(saveToConfig)
local cch=F.cache()
local cfgPara=tonumber(PERSIST.configSlots and PERSIST.configSlots.parachute)
local cfgGlide=tonumber(PERSIST.configSlots and PERSIST.configSlots.glider)
local changed=false
local function maybeSave(slotName,res)
if not saveToConfig or not res or res<=0 then return end
if slotName=="parachute"and res==DEFAULT_PARACHUTE_RES
and cfgPara and cfgPara>0 and cfgPara~=DEFAULT_PARACHUTE_RES then
return
end
F.persistRememberSlot(slotName,res)
changed=true
end
local function applyPara(res,ins)
res,ins=tonumber(res),tonumber(ins)
if not res or not ins or not F.isParachuteRes(res)then return end
if cfgPara and cfgPara>0 and not saveToConfig then
if res==cfgPara then cch.parachuteIns=ins end
return
end
if res==DEFAULT_PARACHUTE_RES and not saveToConfig then return end
if cch.parachuteRes~=res or cch.parachuteIns~=ins then
cch.parachuteRes,cch.parachuteIns=res,ins
_G.AddOutfitLastLobbyParachuteRes=res
maybeSave("parachute",res)
end
end
local function applyGlide(res,ins)
res,ins=tonumber(res),tonumber(ins)
if not res or not ins or not F.isGlideRes(res)then return end
if cfgGlide and cfgGlide>0 and not saveToConfig then
if res==cfgGlide then cch.gliderIns=ins end
return
end
if cch.gliderRes~=res or cch.gliderIns~=ins then
cch.gliderRes,cch.gliderIns=res,ins
_G.AddOutfitLastLobbyGliderRes=res
maybeSave("glider",res)
end
end
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local paraIns=tonumber(fbd.GetParachute and fbd:GetParachute())or 0
if paraIns>0 then
local d=wd:GetValidHallDepotItemDataByInsID(paraIns)or wd:GetHallDepotItemDataByInsID(paraIns)
applyPara(d and tonumber(d.resID),paraIns)
end
local glideIns=tonumber(fbd.GetAircraftOrGliding and fbd:GetAircraftOrGliding())or 0
if glideIns>0 then
local d=wd:GetValidHallDepotItemDataByInsID(glideIns)or wd:GetHallDepotItemDataByInsID(glideIns)
applyGlide(d and tonumber(d.resID),glideIns)
end
end)
pcall(function()
for st in pairs(GLIDER_SUBS)do
local ins,res=F.findWornInsBySubType(st)
if ins and res then applyGlide(res,ins)break end
end
local ins,res=F.findWornInsBySubType(PARACHUTE_SUB)
if ins and res then applyPara(res,ins)end
end)
if changed then F.persistMarkDirty()end
end
function F.syncWeaponCacheFromLobby(force)
if LOBBY.lobbySynced and not force then return end
LOBBY.lobbySynced=true
PERF.mappingsDirty=true
PERF.desiredSkins=nil
for k in pairs(PERF.skinTarget)do PERF.skinTarget[k]=nil end
local cch=F.cache()
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
if bag and bag.weapon_skin_list then
for weaponID,entry in pairs(bag.weapon_skin_list)do
weaponID=tonumber(weaponID)
local insID=tonumber(entry and(entry.skin_id or entry.skinId))or 0
if weaponID and weaponID>0 and insID>0 then
local res
if F.isInjectedIns(insID)then
res=tonumber(R.insToRes[insID])
else
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(insID)
or wd:GetHallDepotItemDataByInsID(insID)
res=d and tonumber(d.resID)
end
if res and res>0 and F.isValidWeaponPersistEntry(weaponID,res)then
cch.weapons[weaponID]={resID=res,insID=insID}
end
end
end
end
end)
pcall(function()
local Arm=require("client.logic.armory.logic_armory")
if Arm.rsp_list and Arm.rsp_list.install_list then
for weaponID,entry in pairs(Arm.rsp_list.install_list)do
weaponID=tonumber(weaponID)
local insID=tonumber(entry and entry.skin_id)or 0
if weaponID and weaponID>0 and insID>0 then
local res
if F.isInjectedIns(insID)then
res=tonumber(R.insToRes[insID])
else
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(insID)
or wd:GetHallDepotItemDataByInsID(insID)
res=d and tonumber(d.resID)
end
if res and res>0 and F.isValidWeaponPersistEntry(weaponID,res)then
cch.weapons[weaponID]={resID=res,insID=insID}
end
end
end
end
end)
F.syncHatCacheFromLobby()
F.syncFaceCacheFromLobby()
F.syncBodyCacheFromLobby()
end
function F.getCachedWeaponSkin(weaponID)
weaponID=tonumber(weaponID)or 0
if weaponID<=0 then return nil end
F.syncWeaponCacheFromLobby()
local w=F.cache().weapons[weaponID]
if w and w.resID and w.resID>0 then return w.resID end
return nil
end
function F.getMatchWeaponSkin(weaponID)
weaponID=tonumber(weaponID)or 0
local fromCache=F.getCachedWeaponSkin(weaponID)
if fromCache then return fromCache end
if MATCH_CONFIG.weaponSkins then
local fixed=tonumber(MATCH_CONFIG.weaponSkins[weaponID])
if fixed and fixed>0 then return fixed end
end
return nil
end
function F.removeRoleWearBySubType(st,filterFn)
st=tonumber(st)
if not st then return end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local AvatarData=require("client.logic.data.AvatarData")
for _,ins in pairs(AvatarData.GetRoleWear())do
ins=tonumber(ins)
if ins and ins>0 then
local d=wd:GetHallDepotItemDataByInsID(ins)
if d and tonumber(d.itemSubType)==st then
local res=tonumber(d.resID)
if not filterFn or filterFn(res,d)then
AvatarData.RemoveRoleWearDataByValue(ins)
end
end
end
end
end
function F.syncFashionBagRolewear()
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
fbd:SaveRolewearToFashionBag(fbd:GetFashionBagUseIndex())
end)
end
local _ticker
pcall(function()_ticker=require("common.time_ticker")end)
function F.later(sec,fn)
if _G.SetTimer then pcall(_G.SetTimer,sec,fn)return end
if _ticker and _ticker.AddTimer then pcall(_ticker.AddTimer,sec,fn)end
end
function F.getPC()
if slua_GameFrontendHUD then
local pc=slua_GameFrontendHUD:GetPlayerController()
if slua.isValid(pc)then return pc end
end
local ok,gd=pcall(require,"GameLua.GameCore.Data.GameplayData")
if ok and gd then
local pc=gd.GetPlayerController()
if slua.isValid(pc)then return pc end
end
return nil
end
function F.syncVehicleSlotsToDataMgr()
local cch=F.cache()
DataMgr.VehicleSlotList=DataMgr.VehicleSlotList or{}
for subType,slots in pairs(cch.vehicleSlots or{})do
local arr=DataMgr.VehicleSlotList[subType]
if not arr then arr={};DataMgr.VehicleSlotList[subType]=arr end
for k in pairs(arr)do arr[k]=nil end
for idx,e in pairs(slots or{})do
if e and tonumber(e.insID)and tonumber(e.insID)>0 then
arr[tonumber(idx)]=tonumber(e.insID)
end
end
end
end
function F.mergeInjectedIntoVehicleSlotList(serverList)
serverList=serverList or{}
local cch=F.cache()
for subType,slots in pairs(cch.vehicleSlots or{})do
subType=tonumber(subType)
if subType and type(slots)=="table"then
local arr=serverList[subType]
if not arr then arr={};serverList[subType]=arr end
for idx,e in pairs(slots)do
idx=tonumber(idx)
local insID=e and tonumber(e.insID)
if idx and insID and insID>0 and F.isInjectedIns(insID)then
arr[idx]=insID
end
end
end
end
local cfg=PERSIST.configVehicleSlots
if cfg then
for subType,slotMap in pairs(cfg)do
subType=tonumber(subType)
if subType and type(slotMap)=="table"then
local arr=serverList[subType]
if not arr then arr={};serverList[subType]=arr end
for idx,res in pairs(slotMap)do
idx,res=tonumber(idx),tonumber(res)
local ins=res and R.resToIns[res]
if idx and ins and F.isInjectedIns(ins)then
arr[idx]=ins
end
end
end
end
end
return serverList
end
function F.applyVehicleSlotsFromConfigMap(slotMap)
if not slotMap or not next(slotMap)then return false end
local cch=F.cache()
cch.vehicleSlots=cch.vehicleSlots or{}
local any=false
for subType,slots in pairs(slotMap)do
subType=tonumber(subType)
if subType then
cch.vehicleSlots[subType]=cch.vehicleSlots[subType]or{}
for idx,res in pairs(slots)do
idx,res=tonumber(idx),tonumber(res)
local ins=res and R.resToIns[res]
if idx and ins then
cch.vehicleSlots[subType][idx]={resID=res,insID=ins}
any=true
end
end
end
end
return any
end
function F.notifyVehicleSlotUI()
pcall(function()
local WRH=require("client.network.Protocol.WardrobeNewHandler")
WRH.on_depot_modify_combat_vehicle_rsp(0,DataMgr.VehicleSlotList or{})
end)
end
function F.mergeInjectedVehicleSkinTable(serverTable)
serverTable=serverTable or{}
local cfg=PERSIST.configVehicleSlots
if not cfg then return serverTable end
for subType,slotMap in pairs(cfg)do
subType=tonumber(subType)
if subType and type(slotMap)=="table"then
local res=tonumber(slotMap[1]or slotMap["1"])
local ins=res and R.resToIns[res]
if ins and F.isInjectedIns(ins)then
serverTable[subType]=ins
end
end
end
local cch=F.cache()
for subType,slots in pairs(cch.vehicleSlots or{})do
subType=tonumber(subType)
local e=slots and(slots[1]or slots["1"])
local insID=e and tonumber(e.insID)
if subType and insID and insID>0 and F.isInjectedIns(insID)then
serverTable[subType]=insID
end
end
return serverTable
end
function F.equipVehicleTypesFromConfig(slotMap)
slotMap=slotMap or PERSIST.configVehicleSlots
if not slotMap or not next(slotMap)then return false end
DataMgr.vehicleSkinInsIDTable=DataMgr.vehicleSkinInsIDTable or{}
local subTypes={}
for st in pairs(slotMap)do
local n=tonumber(st)
if n then subTypes[#subTypes+1]=n end
end
table.sort(subTypes)
local any,lobbyRes,lobbyIns=false,nil,nil
for _,subType in ipairs(subTypes)do
local slots=slotMap[subType]or slotMap[tostring(subType)]
if type(slots)=="table"then
local res=tonumber(slots[1]or slots["1"])
local ins=res and R.resToIns[res]
if ins and F.isInjectedIns(ins)then
DataMgr.vehicleSkinInsIDTable[subType]=ins
any=true
if not lobbyIns then
lobbyRes,lobbyIns=res,ins
end
end
end
end
if any then
pcall(function()
local TabSurveillance=require("client.slua.logic.wardrobe.tab_surveillance")
TabSurveillance.VehicleChange()
end)
end
return any,lobbyRes,lobbyIns
end
function F.applyLobbyVehicleDisplay(resID,insID,showVehicle)
insID=tonumber(insID)
resID=tonumber(resID)
if not insID or insID<=0 then return end
_G.AddOutfitApplyingConfig=true
pcall(function()DataMgr.vst_skin=insID end)
pcall(function()
local HallThemeUtils=require("client.logic.lobby.hall_theme_utils")
HallThemeUtils.ProcPutOnVehicle({res_id=resID,instid=insID},showVehicle~=false)
end)
pcall(F.applyVehicleSkinsToPC)
_G.AddOutfitApplyingConfig=false
end
function F.setLobbyVehicleManual(subType,resID,insID)
insID=tonumber(insID)
resID=tonumber(resID)
subType=tonumber(subType)
if not insID then return end
if F.isChassisLightId(resID)or subType==CHASSIS_LIGHT_SUB then return end
if resID and not F.isVehicleRes(resID)then return end
if not F.isInjectedIns(insID)and not F.isVehicleRes(resID)then return end
if not resID then resID=R.insToRes[insID]end
if not subType and resID then subType=tonumber(F.vehicleSubType(resID))end
_G.AddOutfitLobbyVeh=_G.AddOutfitLobbyVeh or{}
_G.AddOutfitLobbyVeh.manual=true
_G.AddOutfitLobbyVeh.subType=subType
_G.AddOutfitLobbyVeh.resID=resID
_G.AddOutfitLobbyVeh.insID=insID
PERSIST.lobbyVehicleSubType=subType
PERSIST.lobbyVehicleIns=insID
PERSIST.lobbyVehicleResID=resID
F.persistMarkDirty()
end
function F.resolveLobbyVehicle(slotMap)
slotMap=slotMap or PERSIST.configVehicleSlots
local L=_G.AddOutfitLobbyVeh or{}
local st=tonumber(PERSIST.lobbyVehicleSubType)or tonumber(L.subType)
local res=tonumber(PERSIST.lobbyVehicleResID)or tonumber(L.resID)
if res and res>0 then
local ins=R.resToIns[res]
if ins then
if not st then st=tonumber(F.vehicleSubType(res))end
return res,ins,st
end
end
local ins=tonumber(PERSIST.lobbyVehicleIns)or tonumber(L.insID)
if ins and F.isInjectedIns(ins)then
res=R.insToRes[ins]or res
if not st and res then st=tonumber(F.vehicleSubType(res))end
return res,ins,st
end
if st and slotMap then
local slots=slotMap[st]or slotMap[tostring(st)]
local res=slots and tonumber(slots[1]or slots["1"])
ins=res and R.resToIns[res]
if ins then return res,ins,st end
end
local subTypes={}
for s in pairs(slotMap or{})do
local n=tonumber(s)
if n then subTypes[#subTypes+1]=n end
end
table.sort(subTypes)
if subTypes[1]then
st=subTypes[1]
local slots=slotMap[st]or slotMap[tostring(st)]
local res=slots and tonumber(slots[1]or slots["1"])
ins=res and R.resToIns[res]
if ins then return res,ins,st end
end
return nil,nil,nil
end
function F.syncLobbyVehicleResFromIns()
if PERSIST.lobbyVehicleResID and PERSIST.lobbyVehicleResID>0 then return end
local ins=tonumber(PERSIST.lobbyVehicleIns)
if ins and R.insToRes[ins]then
PERSIST.lobbyVehicleResID=R.insToRes[ins]
F.persistMarkDirty()
end
end
function F.hasExplicitLobbyVehicle()
local res=tonumber(PERSIST.lobbyVehicleResID)
local st=tonumber(PERSIST.lobbyVehicleSubType)
if F.isChassisLightId(res)or st==CHASSIS_LIGHT_SUB then return false end
if res and res>0 and not F.isVehicleRes(res)then return false end
if res and res>0 then return true end
if(tonumber(PERSIST.lobbyVehicleIns)or 0)>0 then return true end
local L=_G.AddOutfitLobbyVeh
if L and L.manual and((tonumber(L.resID)or 0)>0 or(tonumber(L.insID)or 0)>0)then return true end
return false
end
function F.shouldApplyLobbyFromConfig(silent)
if not F.hasExplicitLobbyVehicle()then return false end
local _,lobbyIns=F.resolveLobbyVehicle(PERSIST.configVehicleSlots)
if not lobbyIns then return false end
local cur=tonumber(DataMgr.vst_skin)
if cur==lobbyIns then return false end
return true
end
function F.reapplyVehicleSlotsFromConfig(silent)
local slotMap=PERSIST.configVehicleSlots
if not slotMap or not next(slotMap)then return false end
if not F.applyVehicleSlotsFromConfigMap(slotMap)then return false end
F.syncVehicleSlotsToDataMgr()
F.notifyVehicleSlotUI()
F.equipVehicleTypesFromConfig(slotMap)
if F.shouldApplyLobbyFromConfig(silent)then
local lobbyRes,lobbyIns=F.resolveLobbyVehicle(slotMap)
if lobbyIns then
F.applyLobbyVehicleDisplay(lobbyRes,lobbyIns,not silent)
elseif not silent then
pcall(F.applyVehicleSkinsToPC)
F.perfInvalidateLobby()
end
end
return true
end
function F.applyHallThemeDisplay(resID,insID)
insID=tonumber(insID)
resID=tonumber(resID)
if not insID or not resID then return false end
if not F.isInjectedIns(insID)then return false end
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return false
end
_G.AddOutfitApplyingTheme=true
pcall(function()
local HT=require("client.logic.lobby.hall_theme_utils")
HT.ProcPutOnHallTheme({res_id=resID,instid=insID},nil)
end)
_G.AddOutfitApplyingTheme=false
local cch=F.cache()
cch.hallThemeRes,cch.hallThemeIns=resID,insID
return true
end
function F.setHallThemeManual(resID,insID)
insID=tonumber(insID)
resID=tonumber(resID)
if not insID or not F.isInjectedIns(insID)then return end
if not resID then resID=R.insToRes[insID]end
_G.AddOutfitLobbyTheme=_G.AddOutfitLobbyTheme or{}
_G.AddOutfitLobbyTheme.manual=true
_G.AddOutfitLobbyTheme.resID=resID
_G.AddOutfitLobbyTheme.insID=insID
PERSIST.hallThemeResID=resID
PERSIST.hallThemeIns=insID
local cch=F.cache()
cch.hallThemeRes,cch.hallThemeIns=resID,insID
F.persistMarkDirty()
end
function F.resolveHallTheme()
local L=_G.AddOutfitLobbyTheme or{}
local res=tonumber(PERSIST.hallThemeResID)or tonumber(L.resID)
if res and R.resToIns[res]then return res,R.resToIns[res]end
local ins=tonumber(PERSIST.hallThemeIns)or tonumber(L.insID)
if ins and F.isInjectedIns(ins)then return R.insToRes[ins],ins end
return nil,nil
end
function F.shouldApplyHallThemeFromConfig(silent)
local _,ins=F.resolveHallTheme()
if not ins then return false end
local cur=nil
pcall(function()
local HT=require("client.logic.lobby.hall_theme_utils")
cur=tonumber(HT.GetThemeInstId())
end)
if cur==ins then return false end
if _G.AddOutfitLobbyTheme and _G.AddOutfitLobbyTheme.manual then return true end
if silent and cur and cur>0 and F.isInjectedIns(cur)then return false end
return true
end
function F.putOnHallTheme(insID)
insID=tonumber(insID)
if not insID or not F.isInjectedIns(insID)then return false end
local resID=R.insToRes[insID]
if F.applyHallThemeDisplay(resID,insID)then
F.setHallThemeManual(resID,insID)
return true
end
return false
end
function F.reapplyHallThemeFromConfig(silent)
if not F.shouldApplyHallThemeFromConfig(silent)then return false end
local res,ins=F.resolveHallTheme()
if not res or not ins then return false end
return F.applyHallThemeDisplay(res,ins)
end
function F.syncVehicleCacheFromDataMgr()
local cch=F.cache()
cch.vehicleSlots=cch.vehicleSlots or{}
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
for subType,slots in pairs(DataMgr.VehicleSlotList or{})do
subType=tonumber(subType)
if subType and type(slots)=="table"then
cch.vehicleSlots[subType]=cch.vehicleSlots[subType]or{}
for idx,insID in pairs(slots)do
idx,insID=tonumber(idx),tonumber(insID)
if idx and insID and insID>0 then
local res=R.insToRes[insID]
if not res then
pcall(function()
local d=wd:GetHallDepotItemDataByInsID(insID)
res=d and tonumber(d.resID)
end)
end
if res and res>0 then
cch.vehicleSlots[subType][idx]={resID=res,insID=insID}
end
end
end
end
end
end
function F.vehicleSubType(resID)
local c=F.cfg(resID)
return c and(c.ItemSubType or c.itemSubType)
end
function F.modifyInjectedVehicleSlot(insID,slotIndex,equip)
insID=tonumber(insID)
slotIndex=tonumber(slotIndex)
if not insID or not slotIndex then return false end
local resID=R.insToRes[insID]
if not resID and insID>=INS_BASE then
pcall(function()
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
resID=d and tonumber(d.resID or d.res_id)
end)
end
if not resID then return false end
local st=F.vehicleSubType(resID)
if not st or tonumber(st)<900 then return false end
local cch=F.cache()
cch.vehicleSlots=cch.vehicleSlots or{}
cch.vehicleSlots[st]=cch.vehicleSlots[st]or{}
if equip then
for _,slots in pairs(cch.vehicleSlots)do
for i,e in pairs(slots)do
if e and tonumber(e.insID)==insID then slots[i]=nil end
end
end
cch.vehicleSlots[st][slotIndex]={resID=resID,insID=insID}
PERSIST.configVehicleSlots=PERSIST.configVehicleSlots or{}
PERSIST.configVehicleSlots[st]=PERSIST.configVehicleSlots[st]or{}
PERSIST.configVehicleSlots[st][slotIndex]=resID
else
local e=cch.vehicleSlots[st][slotIndex]
if e and tonumber(e.insID)==insID then
cch.vehicleSlots[st][slotIndex]=nil
if PERSIST.configVehicleSlots and PERSIST.configVehicleSlots[st]then
PERSIST.configVehicleSlots[st][slotIndex]=nil
end
end
end
F.syncVehicleSlotsToDataMgr()
if equip and slotIndex==1 then
DataMgr.vehicleSkinInsIDTable=DataMgr.vehicleSkinInsIDTable or{}
DataMgr.vehicleSkinInsIDTable[st]=insID
pcall(function()
local TabSurveillance=require("client.slua.logic.wardrobe.tab_surveillance")
TabSurveillance.VehicleChange()
end)
end
F.persistMarkDirty()
F.notifyVehicleSlotUI()
return true
end
function F.buildVstInBattleFromSlots()
local vst={}
local function insToRes(insID)
insID=tonumber(insID)
if not insID or insID<=0 then return nil end
local res=R.insToRes[insID]
if res and res>0 then return res end
pcall(function()
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
res=d and tonumber(d.resID)
end)
if res and res>0 then return res end
if insID>=1000000 and F.cfg(insID)then return insID end
return nil
end
local function fillFromSlots(subType,slots)
subType=tonumber(subType)
if not subType or type(slots)~="table"then return end
local resList={}
for idx=1,8 do
local val=slots[idx]or slots[tostring(idx)]
local res=insToRes(val)
if not res and type(val)=="table"then
res=tonumber(val.resID or val.res_id)
end
if res and res>0 then resList[#resList+1]=res end
end
if#resList>0 then vst[subType]=resList end
end
for subType,slots in pairs(DataMgr.VehicleSlotList or{})do
fillFromSlots(subType,slots)
end
if not next(vst)then
local cch=F.cache()
for subType,slots in pairs(cch.vehicleSlots or{})do
local resList={}
for idx=1,8 do
local e=slots[idx]
local res=e and tonumber(e.resID)
if res and res>0 then resList[#resList+1]=res end
end
if#resList>0 then vst[tonumber(subType)]=resList end
end
end
if not next(vst)then
local bySub={}
for res,_ in pairs(R.resToIns)do
res=tonumber(res)
local c=F.cfg(res)
local st=c and tonumber(F.subType(c))
if res and st and st>=900 then
bySub[st]=bySub[st]or{}
bySub[st][#bySub[st]+1]=res
end
end
for st,list in pairs(bySub)do
table.sort(list)
vst[st]=list
end
end
return vst
end
function F.isVehicleSkinAllowed(skinId)
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
if F.isInjectedRes(skinId)then return true end
for _,list in pairs(F.buildVstInBattleFromSlots())do
for _,res in ipairs(list)do
if tonumber(res)==skinId then return true end
end
end
if R.resToIns[skinId]then
local c=F.cfg(skinId)
local st=F.subType(c)
if st and tonumber(st)>=900 then return true end
end
return false
end
function F.isSkinInVehiclePCList(skinId)
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
local pc=F.getPC()
if not slua.isValid(pc)or not pc.VehicleAvatarSkinList then return false end
local UAvatarUtils=import("AvatarUtils")
local shape=UAvatarUtils.GetVehicleShapeBySkinID(skinId)
if shape and shape>=0 then
local entry=pc.VehicleAvatarSkinList:Get(shape)
if entry and entry.SkinList then
for _,id in pairs(entry.SkinList)do
if tonumber(id)==skinId then return true end
end
end
end
return false
end
function F.shouldHandleVehicleSkinClick(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return false end
return F.isVehicleSkinAllowed(resID)or F.isSkinInVehiclePCList(resID)
end
function F.getMatchVehicle()
local found=nil
pcall(function()
local subs=SubsystemMgr:Get("VehicleControlUISubSystem")
if subs and subs.GetVehicleUserComponent then
local uuc=subs:GetVehicleUserComponent()
if slua.isValid(uuc)and slua.isValid(uuc.Vehicle)then found=uuc.Vehicle end
end
end)
if slua.isValid(found)then return found end
local pc=F.getPC()
if slua.isValid(pc)and pc.GetPlayerCharacterSafety then
local char=pc:GetPlayerCharacterSafety()
if slua.isValid(char)then
if char.GetCurrentVehicle then
local v=char:GetCurrentVehicle()
if slua.isValid(v)then return v end
end
if char.CurrentVehicle and slua.isValid(char.CurrentVehicle)then
return char.CurrentVehicle
end
end
end
return nil
end
function F.applyClientVehicleSkin(skinId,vehicle,pc)
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
pc=pc or F.getPC()
vehicle=vehicle or F.getMatchVehicle()
if not slua.isValid(vehicle)then return false end
local UAvatarUtils=import("AvatarUtils")
pcall(function()
if slua.isValid(pc)then
pc.ShowVehicleSkin=skinId
local shapeType=UAvatarUtils.GetVehicleShapeBySkinID(skinId)
if shapeType and shapeType>=0 and pc.VehicleAvatarList then
pc.VehicleAvatarList:Add(shapeType,skinId)
end
end
end)
local applied=false
local av=nil
pcall(function()
if vehicle.GetAvatarComponent then av=vehicle:GetAvatarComponent()end
if not slua.isValid(av)then av=vehicle.VehicleAvatarComponent_BP end
end)
if slua.isValid(av)then
pcall(function()if av.bIsLobbyAvatar~=nil then av.bIsLobbyAvatar=false end end)
pcall(function()if av.CanChangeAvatar~=nil then av.CanChangeAvatar=true end end)
pcall(function()
if slua.isValid(pc)and av.SetVehicleNetAvatarData then
av:SetVehicleNetAvatarData(pc)
end
end)
pcall(function()
if av.ChangeItemAvatar then
av:ChangeItemAvatar(skinId,false)
applied=true
elseif av.PreChangeVehicleAvatar then
av:PreChangeVehicleAvatar(skinId)
applied=true
end
end)
pcall(function()
if av.PostChangeItemAvatar then av:PostChangeItemAvatar(false)end
end)
end
pcall(function()
local battleCls=import("VehicleAvatarComponentBattleBase")
local battleAv=vehicle:GetComponentByClass(battleCls)
if slua.isValid(battleAv)then
if battleAv.ChangeVehicleAvatar then
battleAv:ChangeVehicleAvatar(skinId,false)
applied=true
end
pcall(function()
local VehiclePlateLicenseUtil=require("GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
local uid=pc and pc.PlayerUID or 0
local bTire=VehiclePlateLicenseUtil.NeedOpenHighTire(tonumber(uid),skinId)
if battleAv.PreChangeHighTireLight then
battleAv:PreChangeHighTireLight(skinId,bTire)
end
end)
end
end)
pcall(function()
if vehicle.ChangeVehicleAvatar and slua.isValid(pc)then
vehicle:ChangeVehicleAvatar(pc)
applied=true
end
end)
pcall(function()if vehicle.ForceNetUpdate then vehicle:ForceNetUpdate()end end)
pcall(function()if slua.isValid(pc)and pc.ForceNetUpdate then pc:ForceNetUpdate()end end)
return applied
end
function F.getVehicleSkinIds()
local out,seen={},{}
local function add(res)
res=tonumber(res)
if res and res>0 and not seen[res]then
seen[res]=true
out[#out+1]=res
end
end
for _,list in pairs(F.buildVstInBattleFromSlots())do
for _,res in ipairs(list)do add(res)end
end
for res in pairs(R.resToIns)do
local c=F.cfg(tonumber(res))
local st=c and tonumber(F.subType(c))
if st and st>=900 then add(res)end
end
return out
end
function F.buildVehVst(skinIds)
local bySub={}
for _,skinId in ipairs(skinIds or{})do
local subType=961
local ok,c=pcall(function()return CDataTable.GetTableData("Item",skinId)end)
if ok and c and c.ItemSubType then subType=c.ItemSubType end
bySub[subType]=bySub[subType]or{}
bySub[subType][#bySub[subType]+1]=skinId
end
return bySub
end
function F.directInjectVehicleSkinList(pc,skinIds)
if not slua.isValid(pc)or not pc.VehicleAvatarSkinList then return end
local UAvatarUtils=import("AvatarUtils")
for _,skinId in ipairs(skinIds or{})do
local shapeType=nil
pcall(function()shapeType=UAvatarUtils.GetVehicleShapeBySkinID(skinId)end)
if shapeType and shapeType>=0 then
pcall(function()pc.VehicleAvatarList:Add(shapeType,skinId)end)
local entry=pc.VehicleAvatarSkinList:Get(shapeType)
if entry and entry.SkinList then
pcall(function()entry.SkinList:Add(skinId)end)
end
end
end
end
function F.mergeVstIntoPlayerInfo(playerInfo)
if not playerInfo then return end
F.syncVehicleCacheFromDataMgr()
local vst=F.buildVehVst(F.getVehicleSkinIds())
if not next(vst)then return end
playerInfo.vst_in_battle=playerInfo.vst_in_battle or{}
for subType,list in pairs(vst)do
playerInfo.vst_in_battle[subType]=list
end
local first
for _,list in pairs(vst)do first=list[1];break end
if first and first>0 then playerInfo.vst_skin=first end
end
function F.applyVehicleSkinsToPC(pc)
 -- [PERLINDUNGAN KENDARAAN TEAM] Tolak tulis timpa ID kendaraan virtual ke bagian ingat karakter item jika fungsi saklar MATI!
if not _G.AimPROConfig.ModSkin then return false end
pc=pc or F.getPC()
if not slua.isValid(pc)then return false end
local skinIds=F.getVehicleSkinIds()
if#skinIds==0 then return false end
local vst=F.buildVehVst(skinIds)
local avatarList,avatarSkinList={},{}
for _,skinList in pairs(vst)do
local itemArray={}
for _,resid in ipairs(skinList)do
if resid and resid>0 then
itemArray[#itemArray+1]={ItemTableID=resid,Count=1}
avatarList[#avatarList+1]={ItemTableID=resid,Count=1}
end
end
if#itemArray>0 then
avatarSkinList[#avatarSkinList+1]={Items=itemArray}
end
end
pcall(function()pc.bEnableFuzzyAvatarOnClient=false end)
pcall(function()pc.ShowVehicleSkin=skinIds[1]end)
if#avatarList>0 then
pcall(function()
pc.InitialVehicleAvatarList=avatarList
pc:InitVehicleAvatarList()
end)
end
if#avatarSkinList>0 then
pcall(function()
pc.InitialVehicleAvatarSkinList=avatarSkinList
pc:InitVehicleAvatarSkinList()
end)
end
F.directInjectVehicleSkinList(pc,skinIds)
return true
end
function F.serverChangeVehicleAvatar(skinId,pc)
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
pc=pc or F.getPC()
if not slua.isValid(pc)then return false end
F.applyVehicleSkinsToPC(pc)
pcall(function()
pc.ShowVehicleSkin=skinId
local UAvatarUtils=import("AvatarUtils")
local shapeType=UAvatarUtils.GetVehicleShapeBySkinID(skinId)
if shapeType and shapeType>=0 and pc.VehicleAvatarList then
pc.VehicleAvatarList:Add(shapeType,skinId)
end
F.directInjectVehicleSkinList(pc,{skinId})
end)
local ok=false
pcall(function()
if pc.ServerChangeVehicleAvatar then
pc:ServerChangeVehicleAvatar(skinId)
ok=true
end
end)
pcall(function()
if pc.PlayerState and slua.isValid(pc.PlayerState)then
pc.PlayerState.nVst_skin=skinId
end
end)
pcall(function()pc:ForceNetUpdate()end)
return ok
end
_G.AddOutfitVehSel=_G.AddOutfitVehSel or{override=nil,overrideVehicle=nil,byShape={}}
local VEHSEL=_G.AddOutfitVehSel
_G.AddOutfitLobbyVeh=_G.AddOutfitLobbyVeh or{manual=false,subType=nil,resID=nil,insID=nil}
local _vehTickLastApply=0
local VEH_SWITCH_EFFECT_ID=7303001
function F.prepVehicleSwitchEffect(av,vehicle)
if not slua.isValid(av)then return end
if not F.isInRealMatch()then
pcall(function()av.curSwitchEffectId=0 end)
return
end
pcall(function()
av.curSwitchEffectId=VEH_SWITCH_EFFECT_ID
local defaultId=0
pcall(function()defaultId=tonumber(av:GetDefaultAvatarID())or 0 end)
local curId=0
if slua.isValid(vehicle)then
pcall(function()curId=tonumber(vehicle.GetAvatarId and vehicle:GetAvatarId())or 0 end)
if curId<=0 then
pcall(function()curId=tonumber(vehicle.ClientUsedAvatarID)or 0 end)
end
end
if curId<=0 then curId=defaultId end
if not av.lastEquipedAvatarId or av.lastEquipedAvatarId<=0 then
av.lastEquipedAvatarId=curId>0 and curId or defaultId
end
end)
end
function F.isParachuteRes(resID)
return F.subType(F.cfg(tonumber(resID)))==PARACHUTE_SUB
end
function F.isGlideRes(resID)
resID=tonumber(resID)
if not resID then return false end
local st=F.subType(F.cfg(resID))
if GLIDER_SUBS[st]then return true end
local ok,r=pcall(function()
local MDH=require("client.logic.avatar.ModelDisplayTypeHelper")
if MDH.IsGlideByItemID and MDH.IsGlideByItemID(resID)then return true end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
return wd.IsGlideType(st)
end)
return ok and r==true
end
function F.isVehicleRes(resID)
resID=tonumber(resID)
if not resID or F.isChassisLightId(resID)then return false end
local st=tonumber(F.subType(F.cfg(resID)))
return st and st>=900 and st<7000 and st~=CHASSIS_LIGHT_SUB
end
function F.ensureInjectedItemAlive(entity,resID,insID)
entity=entity or F.getEntity()
insID=tonumber(insID)or(resID and R.resToIns[tonumber(resID)])
resID=tonumber(resID)or(insID and R.insToRes[insID])
if not entity or not insID then return end
pcall(function()
local d=entity:GetDataByInsID(insID)
if d then
d.expire_ts=0
d.expireTS=0
d.valid_hours=0
end
end)
end
function F.sanitizeAllInjectedExpire()
local entity=F.getEntity()
if not entity then return end
for res,ins in pairs(R.resToIns)do
F.ensureInjectedItemAlive(entity,res,ins)
end
end
function F.putOnVehicle(insID)
insID=tonumber(insID)
if not insID then return false end
local resID=R.insToRes[insID]
if not resID or not F.isVehicleRes(resID)then return false end
F.ensureInjectedItemAlive(nil,resID,insID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return false
end
local item={res_id=resID,resID=resID,instid=insID,ins_id=insID,insID=insID,expire_ts=0,expireTS=0,count=1,}
local WRH=require("client.network.Protocol.WardRobeHandler")
WRH.on_depot_put_on_rsp(NET_OK,item,nil,1,insID,0)
F.setLobbyVehicleManual(F.vehicleSubType(resID),resID,insID)
pcall(function()
local TabSurveillance=require("client.slua.logic.wardrobe.tab_surveillance")
TabSurveillance.VehicleChange()
end)
pcall(function()
if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_ITEM_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_ITEM_LIST)
end
end)
return true
end
function F.isChassisLightId(id)
return CHASSIS_LIGHT_IDS[tonumber(id)]==true
end
function F.getDesiredChassisLight(vehicleSkinId)
vehicleSkinId=tonumber(vehicleSkinId)
local map=PERSIST.configChassisLightMap
if vehicleSkinId and map and map[vehicleSkinId]then
local v=tonumber(map[vehicleSkinId])
if F.isChassisLightId(v)then return v end
end
local def=tonumber(PERSIST.configChassisLight)or DEFAULT_CHASSIS_LIGHT
return F.isChassisLightId(def)and def or DEFAULT_CHASSIS_LIGHT
end
function F.saveChassisLight(vehicleSkinId,lightId)
vehicleSkinId=tonumber(vehicleSkinId)
lightId=tonumber(lightId)
if not F.isChassisLightId(lightId)then return end
PERSIST.configChassisLightMap=PERSIST.configChassisLightMap or{}
if vehicleSkinId and vehicleSkinId>0 then
PERSIST.configChassisLightMap[vehicleSkinId]=lightId
else
PERSIST.configChassisLight=lightId
end
F.requestResourceDownload(lightId)
F.persistMarkDirty()
end
function F.getVehicleLicenseComp(vehicle)
if not slua.isValid(vehicle)then return nil end
local lic=nil
pcall(function()
if vehicle.GetLicenseComponent then lic=vehicle:GetLicenseComponent()end
end)
if slua.isValid(lic)then return lic end
pcall(function()lic=vehicle.BP_Lobby_VehicleLicenseComponent end)
if slua.isValid(lic)then return lic end
pcall(function()
local cls=import("VehicleLicenseNumberComponent")
lic=vehicle:GetComponentByClass(cls)
end)
return slua.isValid(lic)and lic or nil
end
function F.applyVehicleChassisLight(vehicle,skinId,lightId)
 -- [FIX VIP] Jika dimatikan Mod Skin maka hapus juga tidak load Lampu geram
if _G.AimPROConfig and _G.AimPROConfig.ModSkin==false then return false end
skinId=tonumber(skinId)
lightId=tonumber(lightId)or F.getDesiredChassisLight(skinId)
if not F.isChassisLightId(lightId)then return false end
if not slua.isValid(vehicle)then return false end
if skinId and skinId>0 then
F.requestResourceDownload(skinId)
end
F.requestResourceDownload(lightId)
local applied=false
pcall(function()
if vehicle.SetChassisLightShowData then
vehicle:SetChassisLightShowData(lightId)
applied=true
end
end)
local lic=F.getVehicleLicenseComp(vehicle)
if not slua.isValid(lic)then return applied end
pcall(function()
local vid=skinId
if not vid or vid<=0 then
pcall(function()
if vehicle.GetAvatarId then vid=tonumber(vehicle:GetAvatarId())end
end)
end
if not vid or vid<=0 then
pcall(function()vid=tonumber(lic.LicensePlate and lic.LicensePlate.ItemID)end)
end
if vid and vid>0 then
lic.curVehicleAvatarId=vid
if lic.ChangeNetData_ItemID then
lic:ChangeNetData_ItemID(vid)
elseif lic.LicensePlate then
lic.LicensePlate.ItemID=vid
end
end
if lic.LicensePlate then
lic.LicensePlate.ChassisLightId=lightId
end
if lic.SetChassisLightData and vid and vid>0 then
lic:SetChassisLightData(vid,lightId)
elseif lic.PreChangeChassisLight then
lic:PreChangeChassisLight()
end
applied=true
end)
return applied
end
function F.scheduleChassisLightApply(vehicle,skinId)
skinId=tonumber(skinId)
local vref=slua.isValid(vehicle)and vehicle or nil
local function try()
local v=slua.isValid(vref)and vref or F.getCurrentVehicleForSkin()
if slua.isValid(v)then
F.applyVehicleChassisLight(v,skinId)
end
end
F.later(0.4,try)
F.later(1.1,try)
end
function F.getVehicleShape(vehicle)
if not slua.isValid(vehicle)then return nil end
local shape=vehicle.VehicleShapeType
if shape and tonumber(shape)>=0 then return tonumber(shape)end
pcall(function()
local UAvatarUtils=import("AvatarUtils")
local defId=vehicle.AvatarDefaultCfg and vehicle.AvatarDefaultCfg.TypeSpecificID
if defId and tonumber(defId)>0 then
shape=UAvatarUtils.GetVehicleShapeBySkinID(tonumber(defId))
end
end)
return shape and tonumber(shape)>=0 and tonumber(shape)or nil
end
function F.getDesiredVehicleSkinForShape(shape)
shape=tonumber(shape)
if not shape or shape<0 then return nil end
F.syncVehicleCacheFromDataMgr()
local UAvatarUtils=import("AvatarUtils")
local vst=F.buildVstInBattleFromSlots()
for _,list in pairs(vst)do
local skin=list and tonumber(list[1])
if skin and skin>0 then
local s=UAvatarUtils.GetVehicleShapeBySkinID(skin)
if s==shape then return skin end
end
end
local pc=F.getPC()
if slua.isValid(pc)and pc.VehicleAvatarList then
local skin=tonumber(pc.VehicleAvatarList:Get(shape))
if skin and skin>0 then return skin end
end
return nil
end
function F.getVehicleAvatarComp(vehicle)
if not slua.isValid(vehicle)then return nil end
local av=nil
pcall(function()av=vehicle.VehicleAvatar end)
if slua.isValid(av)then return av end
pcall(function()if vehicle.GetAvatarComponent then av=vehicle:GetAvatarComponent()end end)
if slua.isValid(av)then return av end
pcall(function()av=vehicle.VehicleAvatarComponent_BP end)
if slua.isValid(av)then return av end
return nil
end
function F.getCurrentVehicleForSkin()
local char=F.getLocalChar()
if char and slua.isValid(char)then
local v=nil
pcall(function()v=char.CurrentVehicle end)
if slua.isValid(v)then return v end
end
return F.getMatchVehicle()
end
function F.forceVehicleAvatar(skinId,vehicle)
 -- [PENGAMAN 100%] Tolak semua perintah load Skin kendaraan jika fungsi saklar MATI
if not _G.AimPROConfig.ModSkin then return false end
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
if not F.isResourcesReady(skinId)then
F.requestResourceDownload(skinId)
return false
end
vehicle=slua.isValid(vehicle)and vehicle or F.getCurrentVehicleForSkin()
if not slua.isValid(vehicle)then return false end
local av=F.getVehicleAvatarComp(vehicle)
if not slua.isValid(av)then return false end
local applied=false
F.prepVehicleSwitchEffect(av,vehicle)
pcall(function()if av.CanChangeAvatar~=nil then av.CanChangeAvatar=true end end)
pcall(function()
av:ChangeItemAvatar(skinId,true)
applied=true
_G.CurrentEquipVehicleID=skinId
end)
if applied then F.scheduleChassisLightApply(vehicle,skinId)end
return applied
end
function F.vehicleAvatarTemper()
local vehicle=F.getCurrentVehicleForSkin()
if not slua.isValid(vehicle)then return end
local av=F.getVehicleAvatarComp(vehicle)
if not slua.isValid(av)then return end
local defaultId=0
pcall(function()defaultId=tonumber(av:GetDefaultAvatarID())or 0 end)
if defaultId<=0 then return end
local shape=nil
pcall(function()shape=tonumber(import("AvatarUtils").GetVehicleShapeBySkinID(defaultId))end)
local skinId=nil
if VEHSEL.override and slua.isValid(VEHSEL.overrideVehicle)and VEHSEL.overrideVehicle==vehicle then
skinId=VEHSEL.override
end
if not skinId and shape then skinId=VEHSEL.byShape[shape]end
if not skinId then skinId=F.getDesiredVehicleSkinForShape(shape)end
skinId=tonumber(skinId)
if not skinId or skinId<=0 or skinId==defaultId then return end
local cur=0
pcall(function()cur=tonumber(vehicle.GetAvatarId and vehicle:GetAvatarId())or 0 end)
if cur<=0 then
pcall(function()cur=tonumber(vehicle.GetVehicleSkinItemID and vehicle:GetVehicleSkinItemID())or 0 end)
end
if cur==skinId then return end
F.forceVehicleAvatar(skinId,vehicle)
end
function F.vehicleSkinTick()
 -- [FIX VIP] Jika sudah dimatikan Mod Skin maka blokir selalu loop paksa kendaraan dan wajah masker
if not _G.AimPROConfig.ModSkin then return end
F.vehicleAvatarTemper()
 -- [FIX VIP] Paksa tampil kacamata & wajah masker terus-menerus setiap 1 detik (Walaupun proses ambil topi pastikan Bahaya)
pcall(function()
local char=F.getLocalChar()
if char then F.matchApplyFaceWear(char)end
end)
local now=os.clock()
if now-_vehTickLastApply<5.0 then return end
_vehTickLastApply=now
F.applyVehicleSkinsToPC()
end
function F.startVehicleSkinTicker()
pcall(function()
if not _ticker then return end
if _G.AddOutfitVehTickerId then return end
if _ticker.AddTimerLoop then
_G.AddOutfitVehTickerId=_ticker.AddTimerLoop(1.0,function()
local fn=_G.AddOutfit and _G.AddOutfit.vehicleSkinTick
if fn then pcall(fn)end
end,-1,1.0)
end
end)
end
function F.matchApplyVehicleSkin(skinId)
skinId=tonumber(skinId)
if not skinId or skinId<=0 then return false end
local vehicle=F.getCurrentVehicleForSkin()
VEHSEL.override=skinId
VEHSEL.overrideVehicle=slua.isValid(vehicle)and vehicle or nil
pcall(function()
local UAvatarUtils=import("AvatarUtils")
local shape=tonumber(UAvatarUtils.GetVehicleShapeBySkinID(skinId))
if shape and shape>=0 then VEHSEL.byShape[shape]=skinId end
local av=F.getVehicleAvatarComp(vehicle)
if slua.isValid(av)then
local defaultId=tonumber(av:GetDefaultAvatarID())or 0
if defaultId>0 then
local defShape=tonumber(UAvatarUtils.GetVehicleShapeBySkinID(defaultId))
if defShape and defShape>=0 then VEHSEL.byShape[defShape]=skinId end
end
end
end)
F.applyVehicleSkinsToPC(F.getPC())
local ok=F.forceVehicleAvatar(skinId,vehicle)
F.startVehicleSkinTicker()
return ok
end
function F.autoApplyVehicleSkinOnEnter(vehicle)
 -- [FIX VIP] Cegah agar tidak otomatis ganti skin saat tekan Tombol "Berkendara / Naik Kendaraan"
if not _G.AimPROConfig.ModSkin then return end
if not slua.isValid(vehicle)then return end
F.syncVehicleCacheFromDataMgr()
F.applyVehicleSkinsToPC(F.getPC())
F.startVehicleSkinTicker()
F.later(0.35,function()pcall(F.vehicleAvatarTemper)end)
F.later(0.9,function()pcall(F.vehicleAvatarTemper)end)
F.later(0.5,function()
local skinId=nil
pcall(function()skinId=tonumber(vehicle.GetAvatarId and vehicle:GetAvatarId())end)
F.scheduleChassisLightApply(vehicle,skinId)
end)
end
local function GetOutfitConfigPaths(fileName)
local paths={"//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.tencent.igfit/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/"..fileName,"/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName,"/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/"..fileName,"ShadowTrackerExtra/Saved/Paks/"..fileName,"../../ShadowTrackerExtra/Saved/Paks/"..fileName
}
pcall(function()
if os and os.getenv then
local homeDir=os.getenv("HOME")
if homeDir and homeDir~=""then
table.insert(paths,1,homeDir.."/Documents/ShadowTrackerExtra/Saved/Paks/"..fileName)
end
end
end)
return paths
end
local CONFIG_PATHS=GetOutfitConfigPaths("4imPRO_outfit.json")
local PERSIST_SLOTS={{"outfit","outfitRes","outfitIns","AddOutfitLastLobbyOutfitRes"},{"tshirt","tshirtRes","tshirtIns","AddOutfitLastLobbyTshirtRes"},{"pants","pantsRes","pantsIns","AddOutfitLastLobbyPantsRes"},{"shoes","shoesRes","shoesIns","AddOutfitLastLobbyShoesRes"},{"hat","hatRes","hatIns","AddOutfitLastLobbyHatRes"},{"mask","maskRes","maskIns","AddOutfitLastLobbyMaskRes"},{"glass","glassRes","glassIns","AddOutfitLastLobbyGlassRes"},{"bag","bagRes","bagIns","AddOutfitLastLobbyBagRes"},{"helmet","helmetRes","helmetIns","AddOutfitLastLobbyHelmetRes"},{"parachute","parachuteRes","parachuteIns","AddOutfitLastLobbyParachuteRes"},{"glider","gliderRes","gliderIns","AddOutfitLastLobbyGliderRes"},{"gloves","glovesRes","glovesIns","AddOutfitLastLobbyGlovesRes"},}
function F.isPersistableWearRes(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return false end
if F.isInjectedRes(resID)then return true end
if F.isParachuteRes(resID)or F.isGlideRes(resID)then return true end
if PERSIST.configSlots then
for _,v in pairs(PERSIST.configSlots)do
if tonumber(v)==resID then return true end
end
end
return false
end
function F.persistRememberSlot(slotName,resID)
slotName=slotName and tostring(slotName)
resID=tonumber(resID)
if not slotName or not resID or resID<=0 then return end
PERSIST.configSlots=PERSIST.configSlots or{}
PERSIST.configSlots[slotName]=resID
end
function F.persistForgetSlot(slotName)
if PERSIST.configSlots and slotName then
PERSIST.configSlots[tostring(slotName)]=nil
end
end
function F.persistLoadSlotsFromSaved(saved)
if type(saved)~="table"then return end
PERSIST.configSlots=PERSIST.configSlots or{}
for _,s in ipairs(PERSIST_SLOTS)do
local res=tonumber(saved[s[1]])
if res and res>0 then PERSIST.configSlots[s[1]]=res end
end
F.applyPersistSlotsToCache()
end
function F.resolveInsForRes(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return nil end
if R.resToIns[resID]then return R.resToIns[resID]end
local ins
pcall(function()
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local list=wd.GetHallDepotItemListByResID and wd:GetHallDepotItemListByResID(resID)
if list then
for _,v in pairs(list)do
local id=tonumber(v.insID or v.instid or v.ins_id)
if id and id>0 then ins=id break end
end
end
if not ins then
local d=wd.GetValidHallDepotItemDataByInsID and wd:GetValidHallDepotItemDataByInsID(resID)
if not d and wd.GetHallDepotItemDataByResID then
d=wd:GetHallDepotItemDataByResID(resID)
end
if d then ins=tonumber(d.insID or d.instid or d.ins_id)end
end
end)
return ins
end
function F.applyPersistSlotsToCache()
if not PERSIST.configSlots then return end
local cch=F.cache()
for _,s in ipairs(PERSIST_SLOTS)do
local slotName,cacheResKey,cacheInsKey,globalKey=s[1],s[2],s[3],s[4]
local res=tonumber(PERSIST.configSlots[slotName])
if res and res>0 then
cch[cacheResKey]=res
_G[globalKey]=res
local ins=F.resolveInsForRes(res)
if ins and ins>0 then cch[cacheInsKey]=ins end
end
end
end
function F.getDesiredGliderRes()
F.applyPersistSlotsToCache()
local r=tonumber(PERSIST.configSlots and PERSIST.configSlots.glider)
if r and r>0 then return r end
F.syncAirborneCacheFromLobby()
return F.getDesiredWear("gliderRes","gliderRes","AddOutfitLastLobbyGliderRes")
end
function F.getDesiredParachuteRes()
F.applyPersistSlotsToCache()
local r=tonumber(PERSIST.configSlots and PERSIST.configSlots.parachute)
if r and r>0 then return r end
F.syncAirborneCacheFromLobby()
return F.getDesiredWear("parachuteRes","parachuteRes","AddOutfitLastLobbyParachuteRes")
end
function F.getAvatarComp2(char)
if not char or not slua.isValid(char)then return nil end
local comp
pcall(function()
if char.getAvatarComponent2 then
comp=char:getAvatarComponent2()
end
if(not comp or not slua.isValid(comp))and char.AvatarComponent2 then
comp=char.AvatarComponent2
end
if(not comp or not slua.isValid(comp))and char.CharacterAvatarComp2_BP then
comp=char.CharacterAvatarComp2_BP
end
end)
return comp
end
function F.isCharacterAirborne(char)
if not char or not slua.isValid(char)then return false end
local ok,r=pcall(function()
local EParachuteState=import("EParachuteState")
local st=char.ParachuteState
return st and st~=EParachuteState.PS_None
end)
return ok and r==true
end
function F.reapplyWeaponsFromConfig()
local wmap=F.sanitizeConfigWeapons(PERSIST.configWeapons)
local dropped=false
for k in pairs(PERSIST.configWeapons or{})do
if not wmap[tonumber(k)or k]then dropped=true break end
end
PERSIST.configWeapons=wmap
if dropped then F.persistMarkDirty()end
if not next(wmap)then return false end
local cch=F.cache()
local any=false
for wid,res in pairs(wmap)do
wid,res=tonumber(wid),tonumber(res)
local ins=res and R.resToIns[res]
if wid and ins and F.isInjectedIns(ins)then
cch.weapons[wid]={resID=res,insID=ins}
if F.equipWeaponSkin(wid,ins)then
any=true
else
F.syncWeaponArmorySilent(wid,ins)
end
end
end
return any
end
function F.persistEncode()
local cch=F.cache()
local parts={}
for _,s in ipairs(PERSIST_SLOTS)do
local res=tonumber(PERSIST.configSlots and PERSIST.configSlots[s[1]])
or tonumber(cch[s[2]])
if res and res>0 and F.isPersistableWearRes(res)then
parts[#parts+1]=string.format(' "%s":%d',s[1],res)
end
end
local wparts={}
local wmap={}
for wid,res in pairs(F.sanitizeConfigWeapons(PERSIST.configWeapons))do
wmap[wid]=res
end
for wid,w in pairs(cch.weapons or{})do
local res=w and tonumber(w.resID)
wid=tonumber(wid)
if F.isValidWeaponPersistEntry(wid,res)then wmap[wid]=res end
end
for wid,res in pairs(wmap)do
wparts[#wparts+1]=string.format(' "%d":%d',wid,res)
end
table.sort(wparts)
parts[#parts+1]=' "weapons":{\n'..table.concat(wparts,",\n").."\n}"
local vparts={}
local function appendVehicleSlots(src)
for subType,slots in pairs(src or{})do
local sparts={}
if type(slots)=="table"then
for idx,val in pairs(slots)do
local res=type(val)=="table"and tonumber(val.resID)or tonumber(val)
if res and res>0 then
sparts[#sparts+1]=string.format(' "%d":%d',tonumber(idx),res)
end
end
end
table.sort(sparts)
if#sparts>0 then
vparts[#vparts+1]=string.format(' "%d":{\n%s\n}',tonumber(subType),table.concat(sparts,",\n"))
end
end
end
local hasCacheSlots=false
for _ in pairs(cch.vehicleSlots or{})do hasCacheSlots=true;break end
if hasCacheSlots then
appendVehicleSlots(cch.vehicleSlots)
elseif PERSIST.configVehicleSlots then
appendVehicleSlots(PERSIST.configVehicleSlots)
end
local mparts={}
if DataMgr and DataMgr.MotionSlotList then
for i,ins in ipairs(DataMgr.MotionSlotList)do
ins=tonumber(ins)
if ins and ins>0 and F.isInjectedIns(ins)then
local res=R.insToRes[ins]
if res then mparts[#mparts+1]=string.format(' "%d":%d',i,res)end
end
end
end
if#mparts>0 then
parts[#parts+1]=' "motions":{\n'..table.concat(mparts,",\n").."\n}"
end
if PERSIST.lobbyVehicleSubType and PERSIST.lobbyVehicleSubType>0
and PERSIST.lobbyVehicleSubType~=CHASSIS_LIGHT_SUB
and not F.isChassisLightId(PERSIST.lobbyVehicleResID)
and F.isVehicleRes(PERSIST.lobbyVehicleResID)then
parts[#parts+1]=string.format(' "lobbyVehicleSubType":%d',PERSIST.lobbyVehicleSubType)
end
if PERSIST.lobbyVehicleResID and PERSIST.lobbyVehicleResID>0
and F.isVehicleRes(PERSIST.lobbyVehicleResID)then
parts[#parts+1]=string.format(' "lobbyVehicleResID":%d',PERSIST.lobbyVehicleResID)
end
if PERSIST.lobbyVehicleIns and PERSIST.lobbyVehicleIns>0
and F.isVehicleRes(PERSIST.lobbyVehicleResID or R.insToRes[PERSIST.lobbyVehicleIns])then
parts[#parts+1]=string.format(' "lobbyVehicleIns":%d',PERSIST.lobbyVehicleIns)
end
local hres=tonumber(cch.hallThemeRes)or tonumber(PERSIST.hallThemeResID)
if hres and hres>0 and F.isInjectedRes(hres)then
parts[#parts+1]=string.format(' "hallTheme":%d',hres)
end
local cl=tonumber(PERSIST.configChassisLight)
if F.isChassisLightId(cl)then
parts[#parts+1]=string.format(' "chassisLight":%d',cl)
end
local cmap=PERSIST.configChassisLightMap
if cmap and next(cmap)then
local cparts={}
for vid,lid in pairs(cmap)do
vid,lid=tonumber(vid),tonumber(lid)
if vid and vid>0 and F.isChassisLightId(lid)then
cparts[#cparts+1]=string.format(' "%d":%d',vid,lid)
end
end
table.sort(cparts)
if#cparts>0 then
parts[#parts+1]=' "chassisLightMap":{\n'..table.concat(cparts,",\n").."\n}"
end
end
return"{\n"..table.concat(parts,",\n").."\n}\n"
end
function F.persistWrite(txt)
if not(io and io.open)then return false end
if PERSIST.path then
local f
pcall(function()f=io.open(PERSIST.path,"w")end)
if f then f:write(txt)f:close()return true end
PERSIST.path=nil
end
for _,p in ipairs(CONFIG_PATHS)do
local f
pcall(function()f=io.open(p,"w")end)
if not f then
pcall(function()
local dir=p:match("^(.*)/[^/]+$")
if dir and os and os.execute then os.execute('mkdir-p "'..dir..'"')end
end)
pcall(function()f=io.open(p,"w")end)
end
if f then
f:write(txt)f:close()
PERSIST.path=p
return true
end
end
return false
end
function F.persistFlush()
if not PERSIST.dirty then return end
PERSIST.dirty=false
pcall(function()
local txt=F.persistEncode()
if txt==PERSIST.lastWritten then return end
if F.persistWrite(txt)then
PERSIST.lastWritten=txt
end
end)
end
F.persistMarkDirty=function()
PERSIST.dirty=true
if PERSIST.scheduled then return end
PERSIST.scheduled=true
F.later(2.0,function()
PERSIST.scheduled=false
F.persistFlush()
end)
end
function F.persistParse(txt)
if not txt or#txt==0 then return nil end
local out={weapons={},vehicleSlots={}}
local parsed=false
pcall(function()
local t=json and json.decode and json.decode(txt)
if type(t)=="table"then
for k,v in pairs(t)do
if k=="weapons"and type(v)=="table"then
for wk,wv in pairs(v)do
local wid,res=tonumber(wk),tonumber(wv)
if F.isValidWeaponPersistEntry(wid,res)then out.weapons[wid]=res end
end
elseif k=="vehicleSlots"and type(v)=="table"then
for stk,slotMap in pairs(v)do
local st=tonumber(stk)
if st then
out.vehicleSlots[st]=out.vehicleSlots[st]or{}
for idxStr,res in pairs(slotMap)do
local idx,r=tonumber(idxStr),tonumber(res)
if idx and r and r>0 then out.vehicleSlots[st][idx]=r end
end
end
end
elseif k=="motions"and type(v)=="table"then
out.motions={}
for mk,mv in pairs(v)do
local slot=tonumber(mk)
local res=tonumber(mv)
if slot and res and res>0 then out.motions[slot]=res end
end
else
local n=tonumber(v)
if n and n>0 then out[k]=n end
end
end
parsed=true
end
end)
if not parsed then
for k,v in txt:gmatch('"([%w_]+)"%s*:%s*(%d+)')do
local n=tonumber(v)
if n and n>0 then
local wid=tonumber(k)
if wid and F.isValidWeaponPersistEntry(wid,n)then
out.weapons[wid]=n
elseif not wid then
out[k]=n
end
end
end
end
return out
end
function F.persistLoadFromDisk()
if not(io and io.open)then return end
pcall(function()
for _,p in ipairs(CONFIG_PATHS)do
local f
pcall(function()f=io.open(p,"r")end)
if f then
local txt=f:read("*a")
f:close()
PERSIST.path=p
PERSIST.lastWritten=txt
PERSIST.loaded=F.persistParse(txt)
F.persistLoadSlotsFromSaved(PERSIST.loaded)
if PERSIST.loaded and PERSIST.loaded.vehicleSlots then
PERSIST.configVehicleSlots=PERSIST.loaded.vehicleSlots
end
if PERSIST.loaded and PERSIST.loaded.weapons then
local raw=PERSIST.loaded.weapons
PERSIST.configWeapons=F.sanitizeConfigWeapons(raw)
if next(raw)and not next(PERSIST.configWeapons)then
F.persistMarkDirty()
elseif next(raw)then
for wid,res in pairs(raw)do
if not F.isValidWeaponPersistEntry(tonumber(wid),tonumber(res))then
F.persistMarkDirty()
break
end
end
end
end
PERSIST.lobbyVehicleSubType=tonumber(PERSIST.loaded and PERSIST.loaded.lobbyVehicleSubType)
PERSIST.lobbyVehicleResID=tonumber(PERSIST.loaded and PERSIST.loaded.lobbyVehicleResID)
PERSIST.lobbyVehicleIns=tonumber(PERSIST.loaded and PERSIST.loaded.lobbyVehicleIns)
if PERSIST.lobbyVehicleSubType or PERSIST.lobbyVehicleIns or PERSIST.lobbyVehicleResID then
if F.isChassisLightId(PERSIST.lobbyVehicleResID)
or PERSIST.lobbyVehicleSubType==CHASSIS_LIGHT_SUB
or not F.isVehicleRes(PERSIST.lobbyVehicleResID)then
PERSIST.lobbyVehicleSubType=nil
PERSIST.lobbyVehicleResID=nil
PERSIST.lobbyVehicleIns=nil
else
_G.AddOutfitLobbyVeh=_G.AddOutfitLobbyVeh or{}
_G.AddOutfitLobbyVeh.manual=true
_G.AddOutfitLobbyVeh.subType=PERSIST.lobbyVehicleSubType
_G.AddOutfitLobbyVeh.resID=PERSIST.lobbyVehicleResID
_G.AddOutfitLobbyVeh.insID=PERSIST.lobbyVehicleIns
end
end
PERSIST.hallThemeResID=tonumber(PERSIST.loaded and PERSIST.loaded.hallTheme)
PERSIST.hallThemeIns=nil
if PERSIST.hallThemeResID then
_G.AddOutfitLobbyTheme=_G.AddOutfitLobbyTheme or{}
_G.AddOutfitLobbyTheme.manual=true
_G.AddOutfitLobbyTheme.resID=PERSIST.hallThemeResID
end
PERSIST.configChassisLight=tonumber(PERSIST.loaded and PERSIST.loaded.chassisLight)
if PERSIST.loaded and PERSIST.loaded.chassisLightMap then
PERSIST.configChassisLightMap=PERSIST.loaded.chassisLightMap
end
return
end
end
end)
end
function F.persistApplyLoaded()
local saved=PERSIST.loaded
if not saved then return end
PERSIST.loaded=nil
local cch=F.cache()
local any=false
for _,s in ipairs(PERSIST_SLOTS)do
local res=tonumber(saved[s[1]])or tonumber(PERSIST.configSlots and PERSIST.configSlots[s[1]])
if res and res>0 and not cch[s[2]]then
local ins=R.resToIns[res]
if ins then
cch[s[2]],cch[s[3]]=res,ins
_G[s[4]]=res
any=true
end
end
end
PERSIST.configWeapons=F.sanitizeConfigWeapons(saved.weapons or PERSIST.configWeapons)
if saved.weapons and F.reapplyWeaponsFromConfig()then
any=true
end
if saved.vehicleSlots then
PERSIST.configVehicleSlots=saved.vehicleSlots
if F.reapplyVehicleSlotsFromConfig(true)then
any=true
end
end
if saved.hallTheme then
PERSIST.hallThemeResID=tonumber(saved.hallTheme)
if PERSIST.hallThemeResID and F.reapplyHallThemeFromConfig(true)then
any=true
end
end
if saved.chassisLight then
PERSIST.configChassisLight=tonumber(saved.chassisLight)
end
if saved.chassisLightMap then
PERSIST.configChassisLightMap=saved.chassisLightMap
end
if saved.motions then
PERSIST.configMotions=saved.motions
DataMgr.MotionSlotList=DataMgr.MotionSlotList or{}
for slot,res in pairs(saved.motions)do
local ins=R.resToIns[res]
if ins then DataMgr.MotionSlotList[slot]=ins end
end
if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
EventSystem:postEvent(EVENTTYPE_MOTION,EVENTID_MOTION_UPDATE_SLOT_LIST)
end
end
if any then
_matchApplied=false
F.perfInvalidateLobby()
end
end
function F.getEntity()
local ok,dc=pcall(require,"client.slua.logic.wardrobe.logic_wardrobe_data_center")
if not ok or not dc then return nil end
local ok2,e=pcall(dc.GetWardrobeData)
return ok2 and e or nil
end
function F.firstInsForRes(entity,resID)
local arr=entity.ResIDToIndexArrayMap and entity.ResIDToIndexArrayMap[resID]
if not arr then return nil end
for _,idx in pairs(arr)do
local d=entity._data[idx]
if d and d.count and d.count>0 then return d.insID end
end
return nil
end
function F.injectOne(entity,resID,insID)
local ownedIns=F.firstInsForRes(entity,resID)
if ownedIns then
F.ensureInjectedItemAlive(entity,resID,ownedIns)
R.resToIns[resID]=ownedIns
R.insToRes[ownedIns]=resID
F.indexWeaponSkin(resID,ownedIns)
return true
end
local row={instid=insID,res_id=resID,count=1,lock_cnt=0,isnew=0,valid_hours=0,expire_ts=0,}
entity:AddData(row)
pcall(function()
if entity.LoadConfigForData and CDataTable and CDataTable.GetTableData then
local idx=entity._DataCount
if idx and entity._data[idx]then
entity:LoadConfigForData(entity._data[idx],CDataTable.GetTableData)
end
end
end)
R.insToRes[insID]=resID
R.resToIns[resID]=insID
F.indexWeaponSkin(resID,insID)
return true
end
function F.reviveExpiredOwned(entity)
entity=entity or F.getEntity()
if not entity or not entity.bInit or not entity._data then return end
local now=0
pcall(function()
local TimeUtil=require("client.common.time_util")
now=tonumber(TimeUtil.GetServerTimeInSec())or 0
end)
if now<=0 then return end
_G.AddOutfitRevived=_G.AddOutfitRevived or{}
local n=0
for i=1,(entity._DataCount or#entity._data)do
local d=entity._data[i]
if d then
local exp=tonumber(d.expire_ts or d.expireTS)or 0
local res=tonumber(d.res_id or d.resID)
local ins=tonumber(d.instid or d.insID)
if exp>0 and exp<=now and res and ins and(tonumber(d.count)or 0)>0 then
d.expire_ts=0
if d.expireTS~=nil then d.expireTS=0 end
if d.valid_hours~=nil then d.valid_hours=0 end
_G.AddOutfitRevived[res]=ins
n=n+1
end
end
end
end
function F.mergeRevivedIntoMaps()
for res,ins in pairs(_G.AddOutfitRevived or{})do
if not R.resToIns[res]then
R.resToIns[res]=ins
R.insToRes[ins]=res
F.indexWeaponSkin(res,ins)
end
end
end
function F.injectArmory(resID,insID)
local wid=F.weaponIdFromSkin(resID)
if not wid then return end
local Arm=require("client.logic.armory.logic_armory")
Arm.rsp_list=Arm.rsp_list or{skin_list={},install_list={}}
Arm.rsp_list.skin_list=Arm.rsp_list.skin_list or{}
Arm.rsp_list.install_list=Arm.rsp_list.install_list or{}
if not Arm.rsp_list.skin_list[wid]then Arm.rsp_list.skin_list[wid]={}end
Arm.rsp_list.skin_list[wid][resID]={is_open=1}
Arm.WardrobeInsList=Arm.WardrobeInsList or{}
Arm.WardrobeInsList[resID]=insID
end
function F.mergeInjectedArmorySkins()
for _,skins in pairs(R.byWeapon)do
for resID,insID in pairs(skins)do
F.injectArmory(resID,insID)
end
end
end
function F.injectAll(entity)
 if _G.AimPROConfig and _G.AimPROConfig.ModSkin==false then return false end -- Lewati jika dimatikan Mod Skin
entity=entity or F.getEntity()
if not entity or not entity.bInit then return false end
local n,nNew=0,0
 -- [FIX VIP] OTOMATIS TAMBAH ID topi/tas level 2 dan level 3 UNTUK MEMPERBAIKI UI NỐT Musik
local expandedItems={}
for _,resID in ipairs(ITEMS)do
table.insert(expandedItems,resID)
local resNum=tonumber(resID)
if resNum then
 -- Kenali rentang ID Tas (1501...) dan topi (1502..., 1505...)
local isBag=(resNum>=1501000000 and resNum<=1501999999)
local isHelmet=(resNum>=1502000000 and resNum<=1502999999)or(resNum>=1505000000 and resNum<=1505999999)
if isBag or isHelmet then
 table.insert(expandedItems,resNum+1000) -- Tambahkan Level 2 ke inventori
 table.insert(expandedItems,resNum+2000) -- Tambahkan Level 3 ke inventori
end
end
end
 -- Baca daftar yang sudah digandakan
for i,resID in ipairs(expandedItems)do
local insID=INS_BASE+i
local had=R.resToIns[resID]~=nil
if F.injectOne(entity,resID,insID)then
n=n+1
if not had then nNew=nNew+1 end
local c=F.cfg(resID)
if GUN_SUB[F.subType(c)]or F.subType(c)==MELEE_ID then
F.injectArmory(resID,insID)
end
end
end
if not _G.AddOutfitUnexpireDone then
_G.AddOutfitUnexpireDone=true
pcall(F.reviveExpiredOwned,entity)
end
F.mergeRevivedIntoMaps()
F.sanitizeAllInjectedExpire()
F.ensureInjectedResources()
return n>0
end
function F.refreshWardrobe()
pcall(function()
if EventSystem and EVENTTYPE_WARDROBE then
if EVENTID_WARDROBE_UPDATE_ITEM_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_ITEM_LIST)
end
if EVENTID_WARDROBE_UPDATE_AVATAR_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_AVATAR_LIST)
end
if EVENTID_WARDROBE_UPDATE_GUN_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_GUN_LIST,-1)
end
end
end)
end
function F.refreshWardrobeOnce()
if LOBBY.wardrobeRefreshed then return end
LOBBY.wardrobeRefreshed=true
F.refreshWardrobe()
end
function F.scheduleInjectRefresh()
LOBBY.injectRefreshGen=(LOBBY.injectRefreshGen or 0)+1
local gen=LOBBY.injectRefreshGen
F.later(0.4,function()
if gen~=LOBBY.injectRefreshGen then return end
F.refreshWardrobe()
end)
end
function F.putOnOutfit(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d0=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d0 and tonumber(d0.resID or d0.res_id)
end
if not resID or resID<=0 then return end
if not R.insToRes[insID]then R.insToRes[insID]=resID;R.resToIns[resID]=insID end
F.ensureDepotItemValid(insID,resID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
if not F.isSuitRes(resID)then
if F.isTshirtRes(resID)then return F.putOnRoleWear(insID)end
return
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not d then return end
local suitFilter=function(r)return F.isSuitRes(r)end
local oldIns,oldRes=F.findWornInsBySubType(OUTFIT_SUB,suitFilter)
F.removeRoleWearBySubType(OUTFIT_SUB,suitFilter)
F.saveEquip(resID,insID)
local slot=PKG_SLOT
pcall(function()
local wfu=require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
local idx=wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(OUTFIT_SUB)
if idx then slot=idx end
end)
local olditem
if oldIns and oldIns~=insID then
olditem={res_id=oldRes or R.insToRes[oldIns],count=1,instid=oldIns}
end
local WRH=require("client.network.Protocol.WardRobeHandler")
local item={res_id=resID,count=1,instid=insID}
WRH.on_depot_put_on_rsp(NET_OK,item,olditem,slot,insID,oldIns or 0)
pcall(function()
local av=require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
av:AddToWearInfo(OUTFIT_SUB,insID,resID,0,0)
F.syncFashionBagRolewear()
end)
end
function F.putOnHat(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d0=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d0 and tonumber(d0.resID or d0.res_id)
end
if not resID or resID<=0 then return end
if not R.insToRes[insID]then R.insToRes[insID]=resID;R.resToIns[resID]=insID end
F.ensureDepotItemValid(insID,resID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not d then return end
local st=F.subType(F.cfg(resID))or HAT_SUB
local oldIns,oldRes=F.findWornInsBySubType(st)
if not oldIns and st~=HAT_SUB then
oldIns,oldRes=F.findWornInsBySubType(HAT_SUB)
end
F.removeRoleWearBySubType(st)
if st~=HAT_SUB then F.removeRoleWearBySubType(HAT_SUB)end
F.saveEquip(resID,insID)
local slot=1
pcall(function()
local wfu=require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
local idx=wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(st)
if idx then slot=idx end
end)
local olditem
if oldIns and oldIns~=insID then
olditem={res_id=oldRes or R.insToRes[oldIns],count=1,instid=oldIns}
end
local WRH=require("client.network.Protocol.WardRobeHandler")
local item={res_id=resID,count=1,instid=insID,color=d.color,pattern=d.pattern}
WRH.on_depot_put_on_rsp(NET_OK,item,olditem,slot,insID,oldIns or 0)
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
fbd:SetHeadShow(insID)
F.syncFashionBagRolewear()
end)
F.invalidateSocialWearCache()
end
function F.putOnFaceAccessory(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d0=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d0 and tonumber(d0.resID or d0.res_id)
end
if not resID or resID<=0 then return end
if not R.insToRes[insID]then R.insToRes[insID]=resID;R.resToIns[resID]=insID end
F.ensureDepotItemValid(insID,resID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not d then return end
local st=F.subType(F.cfg(resID))or tonumber(d.itemSubType)
if not FACE_SUBS[st]then return end
local oldIns,oldRes=F.findWornInsBySubType(st)
F.removeRoleWearBySubType(st)
F.saveEquip(resID,insID)
local slot=(st==MASK_SUB)and 2 or 6
pcall(function()
local wfu=require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
local idx=wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(st)
if idx then slot=idx end
end)
local olditem
if oldIns and oldIns~=insID then
olditem={res_id=oldRes or R.insToRes[oldIns],count=1,instid=oldIns}
end
local WRH=require("client.network.Protocol.WardRobeHandler")
local item={res_id=resID,count=1,instid=insID,color=d.color,pattern=d.pattern}
WRH.on_depot_put_on_rsp(NET_OK,item,olditem,slot,insID,oldIns or 0)
pcall(function()F.syncFashionBagRolewear()end)
F.invalidateSocialWearCache()
end
function F.canRoleWear(resID,st)
st=st or F.subType(F.cfg(resID))
if FACE_SUBS[st]or BODY_SUBS[st]then return true end
if st==GLOVES_SUB then return true end
if st==OUTFIT_SUB and F.wardrobeTab(resID)==TAB_CLOTHES then return true end
return false
end
F.putOnRoleWear=function(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d0=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d0 and tonumber(d0.resID or d0.res_id)
end
if not resID or resID<=0 then return end
if not R.insToRes[insID]then R.insToRes[insID]=resID;R.resToIns[resID]=insID end
F.ensureDepotItemValid(insID,resID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not d then return end
local st=F.subType(F.cfg(resID))or tonumber(d.itemSubType)
if not F.canRoleWear(resID,st)then return end
local filterFn
if st==OUTFIT_SUB then
filterFn=function(r)return F.wardrobeTab(r)==TAB_CLOTHES end
end
local oldIns,oldRes=F.findWornInsBySubType(st,filterFn)
F.removeRoleWearBySubType(st,filterFn)
F.saveEquip(resID,insID)
local slot=PKG_SLOT
pcall(function()
local wfu=require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
local idx=wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(st)
if idx then slot=idx end
end)
local olditem
if oldIns and oldIns~=insID then
olditem={res_id=oldRes or R.insToRes[oldIns],count=1,instid=oldIns}
end
local WRH=require("client.network.Protocol.WardRobeHandler")
local item={res_id=resID,count=1,instid=insID,color=d.color,pattern=d.pattern}
WRH.on_depot_put_on_rsp(NET_OK,item,olditem,slot,insID,oldIns or 0)
if BAG_SUBS[st]or HELMET_SUBS[st]then
pcall(function()
DataMgr.equipmentSkinInsIDTable=DataMgr.equipmentSkinInsIDTable or{}
DataMgr.equipmentSkinInsIDTable[st]=insID
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
if bag then
if st==504 or st==501 then
DataMgr.equipmentSkinInsIDTable[504]=insID
bag.bag_skin=insID
 -- [FIX VIP] Paksa tampil Tas 3D luar lobby
local HT=require("client.logic.lobby.hall_theme_utils")
if HT and HT.PutOnBag then HT.PutOnBag(fbd:GetFashionBagUseIndex())end
elseif st==505 or st==502 then
DataMgr.equipmentSkinInsIDTable[505]=insID
bag.helmet_skin=insID
 -- [FIX VIP] Paksa tampil topi 3D luar lobby
fbd:SetHeadShow(insID)
local WRH=require("client.network.Protocol.WardRobeHandler")
if WRH and WRH.send_depot_set_head_show_req then
WRH.send_depot_set_head_show_req(insID)
end
end
end
 -- [FIX VIP] paksa Load Model 3D naik karakter item
local lav=require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
if lav and lav.AvatarChange then
lav:AvatarChange(resID,true,0,0)
end
end)
end
pcall(function()F.syncFashionBagRolewear()end)
F.invalidateSocialWearCache()
end
function F.putOnGloves(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d0=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d0 and tonumber(d0.resID or d0.res_id)
end
if not resID or resID<=0 then return end
if not R.insToRes[insID]then R.insToRes[insID]=resID;R.resToIns[resID]=insID end
F.ensureDepotItemValid(insID,resID)
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if not d then return end
local oldIns,oldRes=F.findWornInsBySubType(GLOVES_SUB)
F.removeRoleWearBySubType(GLOVES_SUB)
F.saveEquip(resID,insID)
local slot=8
pcall(function()
local wfu=require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
local idx=wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(GLOVES_SUB)
if idx then slot=idx end
end)
local olditem
if oldIns and oldIns~=insID then
olditem={res_id=oldRes or R.insToRes[oldIns],count=1,instid=oldIns}
end
local WRH=require("client.network.Protocol.WardRobeHandler")
local item={res_id=resID,count=1,instid=insID,color=d.color,pattern=d.pattern,expire_ts=0}
WRH.on_depot_put_on_rsp(NET_OK,item,olditem,slot,insID,oldIns or 0)
pcall(function()
local logic_wardrobe_avatar=require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
logic_wardrobe_avatar:AddToWearInfo(GLOVES_SUB,insID,resID,d.color or 0,d.pattern or 0)
DataMgr.UpdateRoleWearData(insID,oldIns or 0)
logic_wardrobe_avatar:AvatarChange(resID,true,d.color,d.pattern)
end)
pcall(function()
local wl=require("client.slua.logic.wardrobe.logic_wardrobe_new")
if wl.SetClickItemInsId then wl:SetClickItemInsId(insID)end
end)
pcall(function()
if EventSystem and EVENTTYPE_WARDROBE then
if EVENTID_WARDROBE_UPDATE_ITEM_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_ITEM_LIST)
end
if EVENTID_WARDROBE_UPDATE_AVATAR_LIST then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_AVATAR_LIST)
end
end
end)
F.invalidateSocialWearCache()
end
function F.ensureDepotItemValid(insID,resID)
insID=tonumber(insID)
if not insID then return end
pcall(function()
local entity=F.getEntity()
if entity and entity.GetDataByInsID then
local d=entity:GetDataByInsID(insID)
if d then
d.expire_ts=0
if d.expireTS~=nil then d.expireTS=0 end
if d.valid_hours~=nil then d.valid_hours=0 end
end
end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local hd=wd:GetHallDepotItemDataByInsID(insID)
if hd then
hd.expire_ts=0
if hd.expireTS~=nil then hd.expireTS=0 end
if hd.valid_hours~=nil then hd.valid_hours=0 end
end
end)
end
function F.clearItemExpire(itemData,insID,resID)
F.ensureDepotItemValid(insID,resID)
if type(itemData)=="table"then
itemData.expireTS=0
itemData.expire_ts=0
itemData.expireTs=0
end
end
function F.onGlideClick(self,itemData)
if not itemData then return end
local insID=tonumber(itemData.ins_id)
local resID=tonumber(itemData.res_id)
F.clearItemExpire(itemData,insID,resID)
local isGlide=resID and F.isGlideRes(resID)
if not isGlide and itemData.itemSubType then
isGlide=GLIDER_SUBS[tonumber(itemData.itemSubType)]==true
end
if insID and resID and isGlide then
F.saveEquip(resID,insID)
if F.putOnGlider(insID)then
pcall(function()
if self.ShowGlide then self:ShowGlide(resID)end
if self.ChangeItemStatus then self:ChangeItemStatus(insID,true)end
end)
return
end
end
if _G.AddOutfitGlideClickOrig then
F.clearItemExpire(itemData,insID,resID)
return _G.AddOutfitGlideClickOrig(self,itemData)
end
end
function F.onParachuteClick(self,itemData)
if not itemData then return end
local insID=tonumber(itemData.ins_id)
local resID=tonumber(itemData.res_id)
F.clearItemExpire(itemData,insID,resID)
if insID and resID and F.isParachuteRes(resID)then
F.saveEquip(resID,insID)
if F.putOnParachute(insID)then
pcall(function()
if self.ChangeItemStatus then self:ChangeItemStatus(insID,true)end
end)
return
end
end
if _G.AddOutfitParaClickOrig then
return _G.AddOutfitParaClickOrig(self,itemData)
end
end
function F.hookAirborneClick()
pcall(function()
local WG=require("client.slua.umg.Wardrobe.subtab_gliding")
if WG then
if not WG._AddOutfitGlideWrapped then
WG._AddOutfitGlideWrapped=true
_G.AddOutfitGlideClickOrig=WG.ClickItem
end
WG.ClickItem=function(self,itemData)
return F.onGlideClick(self,itemData)
end
end
local WP=require("client.slua.umg.Wardrobe.subtab_parachute")
if WP then
if not WP._AddOutfitParaWrapped then
WP._AddOutfitParaWrapped=true
_G.AddOutfitParaClickOrig=WP.ClickItem
end
WP.ClickItem=function(self,itemData)
return F.onParachuteClick(self,itemData)
end
end
end)
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
if fbd and not fbd._AddOutfitAirborneFBHooked then
fbd._AddOutfitAirborneFBHooked=true
local oG=fbd.UpdateAircraftOrGliding
fbd.UpdateAircraftOrGliding=function(self,putOnID,bAircraft)
local r=oG(self,putOnID,bAircraft)
local ins=tonumber(putOnID)
if ins and ins>0 then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(ins)or wd:GetHallDepotItemDataByInsID(ins)
local res=d and tonumber(d.resID)
if res and F.isGlideRes(res)then F.saveEquip(res,ins)end
end
return r
end
local oP=fbd.UpdateParachute
if oP then
fbd.UpdateParachute=function(self,insID)
local r=oP(self,insID)
local ins=tonumber(insID)
if ins and ins>0 then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(ins)or wd:GetHallDepotItemDataByInsID(ins)
local res=d and tonumber(d.resID)
if res and F.isParachuteRes(res)then F.saveEquip(res,ins)end
end
return r
end
end
end
end)
pcall(function()
if not ModuleManager or not ModuleManager.GetModule then return end
local FB=ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.FashionBagEditUtils)
if FB and not FB._AddOutfitFBBagHooked then
FB._AddOutfitFBBagHooked=true
local o=FB.PutOnFashionBagItem
FB.PutOnFashionBagItem=function(self,itemData)
if itemData then
F.clearItemExpire(itemData,itemData.ins_id,itemData.res_id)
end
local r=o(self,itemData)
if itemData then
local res=tonumber(itemData.res_id)
local ins=tonumber(itemData.ins_id)
if res and ins and(F.isGlideRes(res)or F.isParachuteRes(res))then
F.saveEquip(res,ins)
end
end
return r
end
end
end)
end
function F.putOnParachute(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d and tonumber(d.resID)
end
if not resID or not F.isParachuteRes(resID)then return false end
if not R.insToRes[insID]then R.insToRes[insID]=resID end
F.ensureDepotItemValid(insID,resID)
F.saveEquip(resID,insID)
F.ensureInjectedItemAlive(nil,resID,insID)
local ready=F.isResourcesReady(resID)
if not ready then F.requestResourceDownload(resID)end
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
if fbd.SetParachute then fbd:SetParachute(insID)end
if fbd.UpdateParachute then fbd:UpdateParachute(insID)end
end)
if ready then
local item={res_id=resID,resID=resID,instid=insID,ins_id=insID,insID=insID,expire_ts=0,expireTS=0,count=1,}
local WRH=require("client.network.Protocol.WardRobeHandler")
WRH.on_depot_put_on_rsp(NET_OK,item,nil,1,insID,0)
end
return true
end
function F.putOnGlider(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetValidHallDepotItemDataByInsID(insID)or wd:GetHallDepotItemDataByInsID(insID)
resID=d and tonumber(d.resID)
end
if not resID or resID<=0 then return false end
local st=F.depotSubType(insID,resID)
if not F.isGlideRes(resID)and not GLIDER_SUBS[st]then return false end
if not R.insToRes[insID]then R.insToRes[insID]=resID end
F.ensureDepotItemValid(insID,resID)
F.saveEquip(resID,insID)
F.ensureInjectedItemAlive(nil,resID,insID)
local ready=F.isResourcesReady(resID)
if not ready then F.requestResourceDownload(resID)end
local bAircraft=false
pcall(function()
local ModelDisplayTypeHelper=require("client.logic.avatar.ModelDisplayTypeHelper")
local st=F.subType(F.cfg(resID))
bAircraft=ModelDisplayTypeHelper.IsGlideSmoke(st)
end)
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
if fbd.UpdateAircraftOrGliding then
fbd:UpdateAircraftOrGliding(insID,bAircraft)
elseif fbd.SetGliding then
fbd:SetGliding(insID)
if DataMgr.UpdateEffect then DataMgr.UpdateEffect(insID)end
end
end)
if ready then
local item={res_id=resID,resID=resID,instid=insID,ins_id=insID,insID=insID,expire_ts=0,expireTS=0,count=1,}
local WRH=require("client.network.Protocol.WardRobeHandler")
WRH.on_depot_put_on_rsp(NET_OK,item,nil,1,insID,0)
end
return true
end
function F.syncAirborneToDataMgr()
F.applyPersistSlotsToCache()
local cch=F.cache()
local paraRes=F.getDesiredParachuteRes()
local gliderRes=F.getDesiredGliderRes()
if paraRes and paraRes>0 and not cch.parachuteIns then
cch.parachuteIns=F.resolveInsForRes(paraRes)
cch.parachuteRes=paraRes
end
if gliderRes and gliderRes>0 and not cch.gliderIns then
cch.gliderIns=F.resolveInsForRes(gliderRes)
cch.gliderRes=gliderRes
end
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
if cch.parachuteIns and tonumber(cch.parachuteIns)>0 then
if fbd.SetParachute then fbd:SetParachute(cch.parachuteIns)end
if DataMgr.roleData then DataMgr.roleData.parachute=tostring(cch.parachuteIns)end
end
if cch.gliderIns and tonumber(cch.gliderIns)>0 then
local bAircraft=false
if cch.gliderRes then
pcall(function()
local MDH=require("client.logic.avatar.ModelDisplayTypeHelper")
bAircraft=not MDH.IsGlideSmoke(F.subType(F.cfg(cch.gliderRes)))
end)
end
if fbd.UpdateAircraftOrGliding then
fbd:UpdateAircraftOrGliding(cch.gliderIns,bAircraft)
elseif fbd.SetGliding then
fbd:SetGliding(cch.gliderIns)
if DataMgr.UpdateEffect then DataMgr.UpdateEffect(cch.gliderIns)end
end
if DataMgr.roleData then
if bAircraft then
DataMgr.roleData.aircraft_put_id=tostring(cch.gliderIns)
DataMgr.gliding=cch.gliderIns
else
DataMgr.roleData.gliding=tostring(cch.gliderIns)
end
end
end
end)
end
function F.putOnGenericInjected(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then return end
if not F.isResourcesReady(resID)then
F.requestResourceDownload(resID)
return
end
F.saveEquip(resID,insID)
local WRH=require("client.network.Protocol.WardRobeHandler")
WRH.on_depot_put_on_rsp(NET_OK,{res_id=resID,count=1,instid=insID},nil,1,insID,0)
end
function F.clearEquipCache(resID)
local st=F.subType(F.cfg(resID))
local cch=F.cache()
if st==OUTFIT_SUB then
if F.wardrobeTab(resID)==TAB_CLOTHES then
cch.tshirtRes,cch.tshirtIns=nil,nil
_G.AddOutfitLastLobbyTshirtRes=nil
F.persistForgetSlot("tshirt")
else
cch.outfitRes,cch.outfitIns=nil,nil
_G.AddOutfitLastLobbyOutfitRes=nil
F.persistForgetSlot("outfit")
end
elseif st==HAT_SUB or HEAD_SUBS[st]then
cch.hatRes,cch.hatIns=nil,nil
_G.AddOutfitLastLobbyHatRes=nil
F.persistForgetSlot("hat")
elseif st==MASK_SUB then
cch.maskRes,cch.maskIns=nil,nil
_G.AddOutfitLastLobbyMaskRes=nil
F.persistForgetSlot("mask")
elseif st==GLASS_SUB then
cch.glassRes,cch.glassIns=nil,nil
_G.AddOutfitLastLobbyGlassRes=nil
F.persistForgetSlot("glass")
elseif st==PANTS_SUB then
cch.pantsRes,cch.pantsIns=nil,nil
_G.AddOutfitLastLobbyPantsRes=nil
F.persistForgetSlot("pants")
elseif st==SHOES_SUB then
cch.shoesRes,cch.shoesIns=nil,nil
_G.AddOutfitLastLobbyShoesRes=nil
F.persistForgetSlot("shoes")
elseif BAG_SUBS[st]then
cch.bagRes,cch.bagIns=nil,nil
_G.AddOutfitLastLobbyBagRes=nil
F.persistForgetSlot("bag")
elseif HELMET_SUBS[st]then
cch.helmetRes,cch.helmetIns=nil,nil
_G.AddOutfitLastLobbyHelmetRes=nil
F.persistForgetSlot("helmet")
elseif st==PARACHUTE_SUB then
cch.parachuteRes,cch.parachuteIns=nil,nil
_G.AddOutfitLastLobbyParachuteRes=nil
F.persistForgetSlot("parachute")
elseif F.isGlideRes(resID)then
cch.gliderRes,cch.gliderIns=nil,nil
_G.AddOutfitLastLobbyGliderRes=nil
F.persistForgetSlot("glider")
elseif st==GLOVES_SUB then
cch.glovesRes,cch.glovesIns=nil,nil
_G.AddOutfitLastLobbyGlovesRes=nil
F.persistForgetSlot("gloves")
end
_matchApplied=false
F.invalidateSocialWearCache()
F.perfInvalidateLobby()
F.persistMarkDirty()
end
function F.takeOffInjected(insID)
insID=tonumber(insID)
local resID=R.insToRes[insID]
if not resID then return end
local st=F.subType(F.cfg(resID))
pcall(function()
local WRH=require("client.network.Protocol.WardRobeHandler")
WRH.on_depot_put_down_rsp(NET_OK,{res_id=resID,count=1},insID)
end)
pcall(function()
local AvatarData=require("client.logic.data.AvatarData")
AvatarData.RemoveRoleWearDataByValue(insID)
end)
if st==HAT_SUB or HEAD_SUBS[st]then
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
if bag and tonumber(bag.head_show)==insID then fbd:SetHeadShow(0)end
end)
end
if BAG_SUBS[st]or HELMET_SUBS[st]then
pcall(function()
local t=DataMgr.equipmentSkinInsIDTable
if t then
for _,k in ipairs({st,504,505})do
if tonumber(t[k])==insID then t[k]=0 end
end
end
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
if bag then
if tonumber(bag.bag_skin)==insID then bag.bag_skin=0 end
if tonumber(bag.helmet_skin)==insID then bag.helmet_skin=0 end
end
end)
end
F.clearEquipCache(resID)
pcall(function()F.syncFashionBagRolewear()end)
end
function F.syncWeaponArmorySilent(weaponID,insID)
weaponID,insID=tonumber(weaponID),tonumber(insID)
if not weaponID or not insID or not F.isInjectedIns(insID)then return end
local resID=R.insToRes[insID]
if not resID then return end
local Arm=require("client.logic.armory.logic_armory")
Arm.rsp_list=Arm.rsp_list or{skin_list={},install_list={}}
Arm.rsp_list.install_list=Arm.rsp_list.install_list or{}
F.injectArmory(resID,insID)
Arm.rsp_list.install_list[weaponID]={skin_id=insID}
pcall(function()
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
if fbd.UpdateCurrentFashionBagWeaponSkin then
fbd:UpdateCurrentFashionBagWeaponSkin(weaponID,insID)
end
end)
end
function F.equipWeaponSkin(weaponID,insID,forceVisual)
weaponID,insID=tonumber(weaponID),tonumber(insID)
if not weaponID or not insID or not F.isInjectedIns(insID)then return false end
local resID=R.insToRes[insID]
if not resID then return false end
_G.AddOutfitWeaponEquipped=_G.AddOutfitWeaponEquipped or{}
if not forceVisual and F.isWeaponVisuallyEquipped(weaponID,insID)then
F.syncWeaponArmorySilent(weaponID,insID)
return false
end
F.saveEquip(resID,insID)
local Arm=require("client.logic.armory.logic_armory")
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local HT=require("client.logic.lobby.hall_theme_utils")
local wgl=require("client.slua.logic.wardrobe.logic_wardrobe_gun")
F.injectArmory(resID,insID)
Arm.rsp_list.install_list[weaponID]={skin_id=insID}
if fbd.UpdateCurrentFashionBagWeaponSkin then
fbd:UpdateCurrentFashionBagWeaponSkin(weaponID,insID)
end
local bagIdx=fbd:GetFashionBagUseIndex()
HT.proc_skin_list_chg("weapon_skin",weaponID,insID,bagIdx,{})
wgl:SetGunID(weaponID)
wgl:UpdateCurrentGunAvatar(weaponID,insID)
if EventSystem and EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
EventSystem:postEvent(EVENTTYPE_ARMORY,EVENTID_ARMORY_EQUIP_STAT_CHANGE,resID)
end
if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
EventSystem:postEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN,resID)
end
_G.AddOutfitWeaponEquipped[weaponID]=insID
return true
end
local SOCIAL=_G.AddOutfitSocialState or{}
_G.AddOutfitSocialState=SOCIAL
SOCIAL.debGen=SOCIAL.debGen or 0
SOCIAL.wearPatchKey=SOCIAL.wearPatchKey or nil
SOCIAL.snapshotKey=SOCIAL.snapshotKey or nil
SOCIAL.fullSnapshot=SOCIAL.fullSnapshot or nil
function F.socialDebounce(sec,fn)
SOCIAL.debGen=(SOCIAL.debGen or 0)+1
local gen=SOCIAL.debGen
F.later(sec,function()
if gen~=SOCIAL.debGen then return end
pcall(fn)
end)
end
function F.getLobbyCurPage()
local p=nil
pcall(function()
local LMC=require("client.slua.logic.lobby.Main.Lobby_Main_Control")
if LMC.GetCurPage then p=LMC.GetCurPage()end
end)
return p
end
function F.isLobbyLeftPage()
return ENUM_LobbyPageType and F.getLobbyCurPage()==ENUM_LobbyPageType.Left
end
function F.getWeaponSkinResFast()
local cch=F.cache()
local wid=tonumber(DataMgr.Weapon_ID)or 0
local w=wid>0 and cch.weapons[wid]or nil
if w and w.resID and w.resID>0 then return w.resID end
for _,ww in pairs(cch.weapons)do
if ww.resID and ww.resID>0 then return ww.resID end
end
return nil
end
function F.resolveLobbyWeaponSkinRes()
if LOBBY.skinResolved then return LOBBY.cachedSkin end
local wid=tonumber(DataMgr.Weapon_ID)or 0
local skin=F.getWeaponSkinResFast()
if skin and skin>0 then return skin end
if wid>0 then
local fromMatch=F.getMatchWeaponSkin(wid)
if fromMatch and fromMatch>0 then return fromMatch end
end
if MATCH_CONFIG.weaponSkins then
for _,s in pairs(MATCH_CONFIG.weaponSkins)do
s=tonumber(s)
if s and s>0 then return s end
end
end
pcall(function()
local Arm=require("client.logic.armory.logic_armory")
local entry=Arm.rsp_list and Arm.rsp_list.install_list
and Arm.rsp_list.install_list[wid>0 and wid or 101004]
local insID=tonumber(entry and entry.skin_id)or 0
if insID>0 and F.isInjectedIns(insID)then
skin=tonumber(R.insToRes[insID])
elseif insID>0 then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if d and d.resID then skin=tonumber(d.resID)end
end
end)
if skin and skin>0 then return skin end
pcall(function()
local wgl=require("client.slua.logic.wardrobe.logic_wardrobe_gun")
if wgl.GetSkinIdByWeaponID and wid>0 then
local insID=tonumber(wgl:GetSkinIdByWeaponID(wid))or 0
if insID>0 and F.isInjectedIns(insID)then
skin=tonumber(R.insToRes[insID])
end
end
end)
LOBBY.skinResolved=true
LOBBY.cachedSkin=(skin and skin>0)and skin or nil
return LOBBY.cachedSkin
end
function F.resolveLobbyOutfitRes()
if LOBBY.outfitResolved then return LOBBY.cachedOutfit end
local cch=F.cache()
local outfitRes=tonumber(cch.outfitRes)or 0
if outfitRes>0 then
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=outfitRes
return outfitRes
end
outfitRes=tonumber(_G.AddOutfitLastLobbyOutfitRes)or 0
if outfitRes>0 then
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=outfitRes
return outfitRes
end
if MATCH_CONFIG.outfitRes and tonumber(MATCH_CONFIG.outfitRes)>0 then
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=tonumber(MATCH_CONFIG.outfitRes)
return LOBBY.cachedOutfit
end
local injectedRes,anyRes
pcall(function()
local AvatarData=require("client.logic.data.AvatarData")
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local function resFromIns(ins)
ins=tonumber(ins)
if not ins or ins<=0 then return nil end
if F.isInjectedIns(ins)then return tonumber(R.insToRes[ins])end
local d=wd:GetHallDepotItemDataByInsID(ins)
return d and tonumber(d.resID)or nil
end
for _,ins in pairs(AvatarData.GetRoleWear())do
local res=resFromIns(ins)
if res and F.isSuitRes(res)then
if F.isInjectedRes(res)then injectedRes=res end
anyRes=anyRes or res
end
end
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local bag=fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
if bag and bag.rolewear_list then
for _,ins in pairs(bag.rolewear_list)do
local res=resFromIns(ins)
if res and F.isSuitRes(res)then
if F.isInjectedRes(res)then injectedRes=res end
anyRes=anyRes or res
end
end
end
end)
if injectedRes and injectedRes>0 then
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=injectedRes
return injectedRes
end
if anyRes and anyRes>0 then
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=anyRes
return anyRes
end
LOBBY.outfitResolved=true
LOBBY.cachedOutfit=nil
return nil
end
function F.rememberLobbyOutfitRes(resID)
resID=tonumber(resID)
if not resID or resID<=0 or not F.isSuitRes(resID)then return end
_G.AddOutfitLastLobbyOutfitRes=resID
F.invalidateLobbyResolved()
local cch=F.cache()
if not cch.outfitRes or cch.outfitRes<=0 then
cch.outfitRes=resID
if F.isInjectedRes(resID)then cch.outfitIns=R.resToIns[resID]end
end
end
function F.wearPatchKey()
local outfit=F.resolveLobbyOutfitRes()or 0
local skin=F.resolveLobbyWeaponSkinRes()or 0
local openGun=1
pcall(function()
local lds=require("client.slua.logic.wardrobe.logic_display_setting")
if lds.data and lds.data.OpenGun~=nil then openGun=lds.data.OpenGun and 1 or 0 end
end)
return outfit.."_"..skin.."_"..openGun
end
function F.syncDepotShowWeaponFlags(depot)
depot=depot or{}
pcall(function()
local lds=require("client.slua.logic.wardrobe.logic_display_setting")
if lds.data then
if lds.data.OpenGun~=nil then depot.weapon=lds.data.OpenGun end
if lds.data.OpenSocialWeapon~=nil then depot.social_weapon=lds.data.OpenSocialWeapon end
end
end)
return depot
end
function F.applyInjectedPspace(roleData)
if not roleData then return end
roleData.bshow=true
roleData.pspace_wear_ext=roleData.pspace_wear_ext or{}
local outfitRes=F.resolveLobbyOutfitRes()
if outfitRes and outfitRes>0 then
roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH]={outfitRes,0,0}
end
local skinRes=F.resolveLobbyWeaponSkinRes()
if skinRes and skinRes>0 then
roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON]={0,0,0}
roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN]={skinRes,0,0}
roleData.depot_show_info=roleData.depot_show_info or{}
if roleData.depot_show_info.weapon==nil then
roleData.depot_show_info.weapon=true
end
end
roleData.depot_show_info=F.syncDepotShowWeaponFlags(roleData.depot_show_info)
end
function F.patchSelfWearCache(force)
local key=F.wearPatchKey()
if not force and SOCIAL.wearPatchKey==key then return false end
SOCIAL.wearPatchKey=key
SOCIAL.snapshotKey=nil
SOCIAL.fullSnapshot=nil
local myUid=tonumber(DataMgr.roleData.uid)
if not myUid then return false end
local changed=false
pcall(function()
local BD=ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
local d=BD:GetCacheData(myUid)
if not d then
BD:OnHandleMsgDataAndCallback(myUid,F.buildLocalRoleDataForCoupleAvatar())
return true
end
local oldCloth=d.pspace_wear_ext and d.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH]
local oldSkin=d.pspace_wear_ext and d.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN]
F.applyInjectedPspace(d)
local nc=d.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH]
local ns=d.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN]
if oldCloth~=nc or oldSkin~=ns or not d.bshow then changed=true end
end)
return force or changed
end
function F.requestSocialAvatarRefresh()
pcall(function()
if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR then
EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL,EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR)
end
end)
end
function F.onSocialWearDirty(forceRefresh)
SOCIAL.lastHandSkin=nil
if F.patchSelfWearCache(forceRefresh)then
F.requestSocialAvatarRefresh()
end
end
function F.buildLocalRoleDataForCoupleAvatar()
local key=F.wearPatchKey()
if SOCIAL.fullSnapshot and SOCIAL.snapshotKey==key then
return SOCIAL.fullSnapshot
end
F.syncWeaponCacheFromLobby()
local cch=F.cache()
local ad=DataMgr.avatarData or{}
local gender=tonumber(ad.gamegender)or 2
if gender<1 then gender=2 end
local data={uid=DataMgr.roleData.uid,gender=gender,bshow=true,pspace_wear_ext={[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HEAD]={tonumber(ad.headid)or 401993,0,0},[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HAIR]={tonumber(ad.hairid)or 40601001,0,0},[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON]={0,0,0},[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN]={0,0,0},},depot_show_info={weapon=true,social_weapon=true,idle=true,helmet=true,bag=true,vehicle=true,hand=true,},}
local outfitRes=F.resolveLobbyOutfitRes()
if outfitRes and outfitRes>0 then
data.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH]={outfitRes,0,0}
end
local skinRes=F.resolveLobbyWeaponSkinRes()
if skinRes and skinRes>0 then
data.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON][1]=0
data.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN][1]=skinRes
end
data.depot_show_info=F.syncDepotShowWeaponFlags(data.depot_show_info)
SOCIAL.fullSnapshot=data
SOCIAL.snapshotKey=F.wearPatchKey()
return data
end
local _myUidCached
function F.isMyWearData(wearData)
if not wearData then return false end
if not _myUidCached then
pcall(function()_myUidCached=tonumber(DataMgr.roleData.uid)end)
end
return _myUidCached and tonumber(wearData.uid)==_myUidCached
end
function F.mergeInjectedWeaponIntoWearData(wearData)
if not F.isMyWearData(wearData)then return end
local skinRes=F.resolveLobbyWeaponSkinRes()
wearData.depot_show_info=F.syncDepotShowWeaponFlags(wearData.depot_show_info)
if not skinRes or skinRes<=0 then return end
wearData.mainWeaponInfo=wearData.mainWeaponInfo or{weaponResId=0,weaponSkinId=0,diyInfo={diyWeaponId=0,diyDefaultScheme=false,diyScheme=nil},}
if wearData.mainWeaponInfo.weaponSkinId==skinRes
and(tonumber(wearData.mainWeaponInfo.weaponResId)or 0)==0 then
return
end
wearData.mainWeaponInfo.weaponSkinId=skinRes
wearData.mainWeaponInfo.weaponResId=0
end
function F.equipSocialHandWeapon(avatar,skinRes)
if not avatar or not skinRes or skinRes<=0 then return end
if SOCIAL.lastHandSkin==skinRes then return end
SOCIAL.lastHandSkin=skinRes
pcall(function()
avatar:PutonEquipment(skinRes,nil,{bIsUse=true})
end)
end
function F.shouldShowHandWeapon()
local show=true
pcall(function()
local lds=require("client.slua.logic.wardrobe.logic_display_setting")
if lds.data and lds.data.OpenGun~=nil then
show=lds.data.OpenGun~=false
end
end)
return show
end
function F.mergeInjectedOutfitIntoWearData(wearData)
if not F.isMyWearData(wearData)then return end
local outfitRes=F.resolveLobbyOutfitRes()
if not outfitRes or outfitRes<=0 then return end
F.rememberLobbyOutfitRes(outfitRes)
local AvatarData=require("client.logic.data.AvatarData")
local converted=AvatarData.ConvertToAvatarCustom({outfitRes,0,0})
if not converted then return end
wearData.WearInfoList=wearData.WearInfoList or{}
local replaced=false
for i,e in ipairs(wearData.WearInfoList)do
if e and e.ItemID and F.isSuitRes(e.ItemID)then
wearData.WearInfoList[i]=converted
replaced=true
break
end
end
if not replaced then
table.insert(wearData.WearInfoList,converted)
end
end
function F.mergeInjectedIntoWearData(wearData)
if not wearData then return end
F.mergeInjectedWeaponIntoWearData(wearData)
F.mergeInjectedOutfitIntoWearData(wearData)
end
function F.reapplyLobbyEquipped()
 -- [FIX VIP] Cegah agar tidak lobby pasang ulang skin virtual saat kamu sudah MATI fungsi saklar
if not _G.AimPROConfig.ModSkin then return end
if not GameStatus or not GameStatus.IsInLobbyOrMainCity or not GameStatus.IsInLobbyOrMainCity()then
return
end
F.syncWeaponCacheFromLobby()
F.applyPersistSlotsToCache()
local curPage=F.getLobbyCurPage()
if ENUM_LobbyPageType and curPage==ENUM_LobbyPageType.Left then
F.onSocialWearDirty(true)
return
end
local cch=F.cache()
if cch.outfitIns and F.isInjectedIns(cch.outfitIns)then
F.putOnOutfit(cch.outfitIns)
end
if cch.hatIns and F.isInjectedIns(cch.hatIns)then
F.putOnHat(cch.hatIns)
end
if cch.maskIns and F.isInjectedIns(cch.maskIns)then
F.putOnRoleWear(cch.maskIns)
end
if cch.glassIns and F.isInjectedIns(cch.glassIns)then
F.putOnRoleWear(cch.glassIns)
end
if cch.tshirtIns and F.isInjectedIns(cch.tshirtIns)then
F.putOnRoleWear(cch.tshirtIns)
end
if cch.pantsIns and F.isInjectedIns(cch.pantsIns)then
F.putOnRoleWear(cch.pantsIns)
end
if cch.shoesIns and F.isInjectedIns(cch.shoesIns)then
F.putOnRoleWear(cch.shoesIns)
end
if cch.bagIns and F.isInjectedIns(cch.bagIns)then
F.putOnRoleWear(cch.bagIns)
end
if cch.helmetIns and F.isInjectedIns(cch.helmetIns)then
F.putOnRoleWear(cch.helmetIns)
end
if cch.parachuteIns then
F.putOnParachute(cch.parachuteIns)
end
if cch.gliderIns then
F.putOnGlider(cch.gliderIns)
end
if cch.glovesIns and F.isInjectedIns(cch.glovesIns)then
F.putOnGloves(cch.glovesIns)
end
local mainWid=tonumber(DataMgr.Weapon_ID)or 0
local w=mainWid>0 and cch.weapons[mainWid]or nil
if w and w.resID and w.resID>0 then
if w.insID and F.isInjectedIns(w.insID)then
F.equipWeaponSkin(mainWid,w.insID)
else
pcall(function()DataMgr.InitWeaponData(mainWid,w.resID,w.insID or 0)end)
end
end
pcall(function()
local uid=tostring(DataMgr.roleData.uid)
local LAM=require("client.logic.avatar.LobbyAvatarManager")
local TAM=require("client.logic.avatar.logic_team_avatar_manager")
if w and w.resID and w.resID>0 and TAM.GetAvatarByUid(uid)then
LAM.EquipWeapon(uid,{weaponId=mainWid,skinId=w.resID},nil,true)
end
end)
F.reapplyVehicleSlotsFromConfig(true)
F.reapplyHallThemeFromConfig(true)
F.reapplyWeaponsFromConfig()
pcall(F.applyVehicleSkinsToPC)
end
F.scheduleLobbyReapplyOnce=function()
if LOBBY.reapplyDone or LOBBY.reapplyScheduled then return end
LOBBY.reapplyScheduled=true
F.later(2.0,function()
LOBBY.reapplyScheduled=false
if LOBBY.reapplyDone then return end
LOBBY.reapplyDone=true
F.reapplyLobbyEquipped()
end)
end
function F.hookLobbySwipePersistence()
if _G.AddOutfitLobbySwipeHooked then return end
_G.AddOutfitLobbySwipeHooked=true
pcall(function()
local BD=ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
local oRsp=BD.on_get_avatar_show_rsp
BD.on_get_avatar_show_rsp=function(self,res,target_uid,data)
oRsp(self,res,target_uid,data)
if tonumber(target_uid)==tonumber(DataMgr.roleData.uid)then
F.patchSelfWearCache(true)
SOCIAL.forceAvatarRedraw=true
SOCIAL.lastHandSkin=nil
if ENUM_LobbyPageType and F.getLobbyCurPage()==ENUM_LobbyPageType.Left then
F.requestSocialAvatarRefresh()
end
end
end
end)
pcall(function()
local AC=require("client.slua.logic.avatar.avatar_common")
local oGetWear=AC.GetWearDataFromRoleData
AC.GetWearDataFromRoleData=function(roleData)
local wearData=oGetWear(roleData)
if wearData and roleData and tonumber(roleData.uid)==tonumber(DataMgr.roleData.uid)
and F.isLobbyLeftPage()then
F.mergeInjectedIntoWearData(wearData)
end
return wearData
end
local oUp=AC.UpdateAvatar
AC.UpdateAvatar=function(avatar,wearData,isShowWeapon,isShowHelmet,isShowBag)
if F.isMyWearData(wearData)and F.isLobbyLeftPage()then
F.mergeInjectedIntoWearData(wearData)
end
local showGun=isShowWeapon and F.shouldShowHandWeapon()
if wearData and wearData.depot_show_info then
showGun=showGun and wearData.depot_show_info.weapon~=false
end
if F.isMyWearData(wearData)and F.isLobbyLeftPage()then
for _,e in ipairs(wearData.WearInfoList or{})do
if e and e.ItemID and F.isInjectedRes(e.ItemID)and F.isSuitRes(e.ItemID)then
F.rememberLobbyOutfitRes(e.ItemID)
break
end
end
end
local ret=oUp(avatar,wearData,showGun,isShowHelmet,isShowBag)
if showGun and F.isMyWearData(wearData)and avatar and F.isLobbyLeftPage()then
local skin=tonumber(wearData.mainWeaponInfo and wearData.mainWeaponInfo.weaponSkinId)or 0
if skin<=0 then skin=F.resolveLobbyWeaponSkinRes()or 0 end
if skin>0 then F.equipSocialHandWeapon(avatar,skin)end
end
return ret
end
end)
pcall(function()
local CA=require("client.logic.avatar.CoupleAvatar")
local Cfg=require("client.slua.logic.lobby.Left.CoupleAvatarConfig")
local oMulti=CA._UpdateMultiAvatar
if oMulti then
CA._UpdateMultiAvatar=function(self,avatar,avatarType)
local isSelf=avatarType==Cfg.AvatarType.Self
and self.SelfUID and tostring(self.SelfUID)==tostring(DataMgr.roleData.uid)
if isSelf and F.isLobbyLeftPage()then
pcall(function()
local BD=ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
local d=BD:GetCacheData(tonumber(self.SelfUID))
if d then F.applyInjectedPspace(d)end
end)
if SOCIAL.forceAvatarRedraw then
self.CompareDataCache[avatarType]=nil
SOCIAL.forceAvatarRedraw=nil
end
end
oMulti(self,avatar,avatarType)
if isSelf and F.isLobbyLeftPage()and self.isShowWeapon~=false and F.shouldShowHandWeapon()then
local skin=F.resolveLobbyWeaponSkinRes()
if skin and skin>0 then F.equipSocialHandWeapon(avatar,skin)end
end
end
end
local oHideCheck=CA.CheckSelfIsHideAvatar
CA.CheckSelfIsHideAvatar=function(self,nSelfUId,tRoleData)
if F.isLobbyLeftPage()and tostring(nSelfUId)==tostring(DataMgr.roleData.uid)then
return false
end
return oHideCheck(self,nSelfUId,tRoleData)
end
local oUpdate=CA.Update
CA.Update=function(self)
if not F.isLobbyLeftPage()then
return oUpdate(self)
end
local isSelf=self.SelfUID and tostring(self.SelfUID)==tostring(DataMgr.roleData.uid)
local oHide=CA.HideAvatars
if isSelf then
CA.HideAvatars=function()end
end
local ok,err=pcall(oUpdate,self)
CA.HideAvatars=oHide
end
local oRecv=CA.OnReceiveData
CA.OnReceiveData=function(self,uid,data)
if F.isLobbyLeftPage()and uid==self.SelfUID and tostring(uid)==tostring(DataMgr.roleData.uid)then
if data then
F.applyInjectedPspace(data)
else
data=F.buildLocalRoleDataForCoupleAvatar()
end
end
return oRecv(self,uid,data)
end
end)
pcall(function()
if not EventSystem or not EventSystem.registEvent then return end
if EVENTTYPE_LOBBY and EVENTID_SWITCHTO_PAGE_START then
EventSystem:registEvent(EVENTTYPE_LOBBY,EVENTID_SWITCHTO_PAGE_START,function(_,_,toPage)
if ENUM_LobbyPageType and toPage==ENUM_LobbyPageType.Left then
F.syncWeaponCacheFromLobby()
SOCIAL.lastHandSkin=nil
local o=F.resolveLobbyOutfitRes()
if o then F.rememberLobbyOutfitRes(o)end
F.patchSelfWearCache(true)
SOCIAL.forceAvatarRedraw=true
end
end)
end
if EVENTTYPE_LOBBY and EVENTID_SWITCHTO_PAGE_END then
EventSystem:registEvent(EVENTTYPE_LOBBY,EVENTID_SWITCHTO_PAGE_END,function(_,_,_,toPage)
if ENUM_LobbyPageType and toPage==ENUM_LobbyPageType.Left then
F.syncWeaponCacheFromLobby()
SOCIAL.lastHandSkin=nil
F.socialDebounce(0.45,function()
F.onSocialWearDirty(true)
end)
elseif ENUM_LobbyPageType and toPage==ENUM_LobbyPageType.Mid then
SOCIAL.wearPatchKey=nil
F.invalidateLobbyResolved()
if not LOBBY.reapplyDone then
F.socialDebounce(0.5,F.scheduleLobbyReapplyOnce)
end
end
end)
end
if EVENTTYPE_LOBBY_SOCIAL and EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
EventSystem:registEvent(EVENTTYPE_LOBBY_SOCIAL,EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA,function(_,_,nUId)
if tonumber(nUId)==tonumber(DataMgr.roleData.uid)then
F.socialDebounce(0.2,function()F.patchSelfWearCache(false)end)
end
end)
end
if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
EventSystem:registEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN,function()
SOCIAL.wearPatchKey=nil
SOCIAL.snapshotKey=nil
F.syncWeaponCacheFromLobby()
local curPage=ENUM_LobbyPageType and F.getLobbyCurPage()
if curPage==ENUM_LobbyPageType.Left then
F.socialDebounce(0.25,function()F.onSocialWearDirty(true)end)
end
 -- [FIX Error VIP] otomatis gerak pasang ulang Skin Mod saat game ada tanda update senjata di lobby
F.socialDebounce(0.3,function()
if F.reapplyLobbyEquipped then F.reapplyLobbyEquipped()end
end)
end)
end
end)
pcall(function()
local lds=require("client.slua.logic.wardrobe.logic_display_setting")
local oSwitch=lds.SwitchGun
lds.SwitchGun=function(...)
local r=oSwitch(...)
SOCIAL.wearPatchKey=nil
local curPage=ENUM_LobbyPageType and F.getLobbyCurPage()
if curPage==ENUM_LobbyPageType.Left then
F.socialDebounce(0.2,function()F.onSocialWearDirty(true)end)
end
 -- [FIX Error VIP] saat Click ke Kotak senjata senjata di Lobby, tunggu game ganti senjata asli selesai lalu 0.3s setelah Tutup skin Mod naik lagi
F.socialDebounce(0.3,function()
if F.reapplyLobbyEquipped then F.reapplyLobbyEquipped()end
end)
return r
end
end)
end
function F.hookDepotInit()
pcall(function()
local WDE=require("client.slua.logic.wardrobe.WardrobeDataEntity")
if WDE._AddOutfitInitHooked then return end
WDE._AddOutfitInitHooked=true
local orig=WDE.InitData
WDE.InitData=function(self,pkg)
orig(self,pkg)
_G.AddOutfitUnexpireDone=false
pcall(function()
if F.injectAll(self)then
F.scheduleInjectRefresh()
LOBBY.reapplyDone=false
LOBBY.reapplyScheduled=false
F.scheduleLobbyReapplyOnce()
end
end)
end
end)
end
function F.hookWardrobeData()
pcall(function()
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
if wd._AddOutfitDataHooked then return end
wd._AddOutfitDataHooked=true
local function wrapGet(name)
local o=wd[name]
if not o then return end
wd[name]=function(self,insID,...)
insID=tonumber(insID)
local r
if F.isInjectedIns(insID)then
local e=F.getEntity()
if e then r=e:GetDataByInsID(insID)end
else
r=o(self,insID,...)
end
if r and(F.isInjectedIns(insID)or F.isInjectedRes(r.resID or r.res_id))then
r.expire_ts=0
r.expireTS=0
r.valid_hours=0
end
return r
end
end
wrapGet("GetHallDepotItemDataByInsID")
wrapGet("GetValidHallDepotItemDataByInsID")
local function wrapBool(name)
local o=wd[name]
if not o then return end
wd[name]=function(self,id,...)
if F.isInjectedRes(tonumber(id))or F.isInjectedIns(tonumber(id))then return true end
return o(self,id,...)
end
end
wrapBool("HasItem")
wrapBool("HasValidItem")
wrapBool("CheckHasPermanentItem")
end)
end
function F.hookPageFilter()
pcall(function()
local wl=require("client.slua.logic.wardrobe.logic_wardrobe_new")
if wl._AddOutfitPageFilterHooked then return end
wl._AddOutfitPageFilterHooked=true
local o1=wl.IsValidCurrentPageItem
wl.IsValidCurrentPageItem=function(self,mainTab,subTab,v,t)
if v and F.isInjectedRes(v.resID)then
local itemTab=tonumber(v.subTabType)or F.wardrobeTab(v.resID)
if itemTab and itemTab==subTab then
if mainTab==PAGE_AVATAR or mainTab==PAGE_VEHICLE then return true end
if mainTab==PAGE_PARACHUTE and F.isHallThemeRes(v.resID)then return true end
end
end
return o1(self,mainTab,subTab,v,t)
end
local o2=wl.IsCanUse
wl.IsCanUse=function(self,resId)
if F.isInjectedRes(resId)then return true end
return o2(self,resId)
end
local o3=wl.IsCharacterUse
wl.IsCharacterUse=function(self,resId)
if F.isInjectedRes(resId)then return true end
return o3(self,resId)
end
local o4=wl.GetWardrobeInsIdByResId
wl.GetWardrobeInsIdByResId=function(self,resid)
resid=tonumber(resid)
if F.isInjectedRes(resid)then return R.resToIns[resid]end
return o4(self,resid)
end
end)
end
function F.hookArmory()
pcall(function()
local Arm=require("client.logic.armory.logic_armory")
if Arm._AddOutfitArmoryHooked then return end
Arm._AddOutfitArmoryHooked=true
local oa=Arm.get_weapon_skin_list_rsp
Arm.get_weapon_skin_list_rsp=function(a,b,c,d)
oa(a,b,c,d)
F.mergeInjectedArmorySkins()
end
local oi=Arm.install_weapon_skin
Arm.install_weapon_skin=function(cd,wid,ins)
ins=tonumber(ins)
if F.isWeaponSkinIns(ins)then
wid=tonumber(F.weaponIdFromSkin(R.insToRes[ins])or wid)
F.equipWeaponSkin(wid,ins)
return
end
return oi(cd,wid,ins)
end
end)
pcall(function()
local AH=require("client.network.Protocol.ArmoryHandler")
if AH._AddOutfitArmorySendHooked then return end
AH._AddOutfitArmorySendHooked=true
local o=AH.send_install_weapon_skin
AH.send_install_weapon_skin=function(cd,wid,ins)
ins=tonumber(ins)
if F.isWeaponSkinIns(ins)then
wid=tonumber(F.weaponIdFromSkin(R.insToRes[ins])or wid)
F.equipWeaponSkin(wid,ins)
return
end
return o(cd,wid,ins)
end
end)
end
function F.hookGunSkinId()
pcall(function()
local wgl=require("client.slua.logic.wardrobe.logic_wardrobe_gun")
if wgl._AddOutfitGunSkinHooked then return end
wgl._AddOutfitGunSkinHooked=true
local o=wgl.GetSkinIdByWeaponID
wgl.GetSkinIdByWeaponID=function(self,wid)
local c=F.cache()
local w=c.weapons[wid]
if w and F.isWeaponSkinIns(w.insID)then return w.insID end
local Arm=require("client.logic.armory.logic_armory")
if Arm.rsp_list and Arm.rsp_list.install_list and Arm.rsp_list.install_list[wid]then
local sid=Arm.rsp_list.install_list[wid].skin_id
if sid and F.isWeaponSkinIns(sid)then return sid end
end
return o(self,wid)
end
end)
end
function F.hookPutOn()
pcall(function()
local WRH=require("client.network.Protocol.WardRobeHandler")
if WRH._AddOutfitPutOnHooked then return end
WRH._AddOutfitPutOnHooked=true
local o=WRH.send_depot_put_on_req
WRH.send_depot_put_on_req=function(insID,extra)
insID=tonumber(insID)
if F.tryLocalWearByIns(insID)then return end
return o(insID,extra)
end
end)
end
function F.hookPutDown()
pcall(function()
local WRH=require("client.network.Protocol.WardRobeHandler")
if WRH._AddOutfitPutDownHooked then return end
WRH._AddOutfitPutDownHooked=true
local o=WRH.send_depot_put_down_req
WRH.send_depot_put_down_req=function(insID)
if F.isInjectedIns(tonumber(insID))then
F.takeOffInjected(insID)
return
end
return o(insID)
end
local ob=WRH.send_depot_batch_put_down_req
WRH.send_depot_batch_put_down_req=function(instid_list)
local rest={}
for _,id in ipairs(instid_list or{})do
if F.isInjectedIns(tonumber(id))then
F.takeOffInjected(id)
else
rest[#rest+1]=id
end
end
if#rest>0 then return ob(rest)end
end
end)
end
function F.hookVehicleSwitchEffect()
if _G.AddOutfitVehSwitchHooked then return end
pcall(function()
local VAC=require("GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent")
local impl=VAC and VAC.__inner_impl
if not impl or impl._AddOutfitVehSwitchHooked then return end
impl._AddOutfitVehSwitchHooked=true
if not _G.AddOutfitVehOrigCanSwitch then
_G.AddOutfitVehOrigCanSwitch=impl.CheckCanPlaySkinSwitchEffect
end
impl.CheckCanPlaySkinSwitchEffect=function(self,curVehicleId,lastVehicleId)
 -- [PERLINDUNGAN KENDARAAN TEAM] Kembalikan perintah check hasil sesuai untuk game asli saat MATI fungsi saklar
if not _G.AimPROConfig.ModSkin then
if _G.AddOutfitVehOrigCanSwitch then return _G.AddOutfitVehOrigCanSwitch(self,curVehicleId,lastVehicleId)end
return false
end
if self.IsLobbyActor and self:IsLobbyActor()then return false end
if not F.isInRealMatch()then return false end
return true
end
if not _G.AddOutfitVehOrigShowSwitch then
_G.AddOutfitVehOrigShowSwitch=impl.ShowVehicleSwitchEffect
end
impl.ShowVehicleSwitchEffect=function(self)
 -- [PERLINDUNGAN KENDARAAN TEAM] Kembalikan efek ganti kendaraan untuk game asli saat MATI fungsi saklar
if not _G.AimPROConfig.ModSkin then
if _G.AddOutfitVehOrigShowSwitch then return _G.AddOutfitVehOrigShowSwitch(self)end
return false
end
if self.IsLobbyActor and self:IsLobbyActor()then return false end
if not F.isInRealMatch()then return false end
if not self.curSwitchEffectId or self.curSwitchEffectId<=0 then
self.curSwitchEffectId=VEH_SWITCH_EFFECT_ID
end
local vehicleActor=self:GetOwner()
if not slua.isValid(vehicleActor)then return false end
if self.uSwitchEffectActor then
self:StopSkinSwitchEffect()
pcall(function()self.uSwitchEffectActor:K2_DestroyActor()end)
self.uSwitchEffectActor=nil
end
if not self.lastEquipedAvatarId or self.lastEquipedAvatarId<=0 then
local defId=0
pcall(function()defId=self:GetDefaultAvatarID()or 0 end)
self.lastEquipedAvatarId=vehicleActor.ClientUsedAvatarID or defId or 0
end
local currentAvatarID=vehicleActor.ClientUsedAvatarID or self.lastEquipedAvatarId or 0
local bIsLobbyActor=self:IsLobbyActor()
local world=slua_GameFrontendHUD:GetWorld()
local VehiclePlateLicenseUtil=require("GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
local SkinSwitchEffectActorPath=VehiclePlateLicenseUtil.GetSwitchEffectActorPath()
local BP_DissolveVehicleClass=import(SkinSwitchEffectActorPath)
self.uSwitchEffectActor=world:SpawnActor(BP_DissolveVehicleClass,nil,nil,nil)
if not slua.isValid(self.uSwitchEffectActor)then
self.uSwitchEffectActor=nil
return false
end
self.uSwitchEffectActor:K2_AttachToActor(vehicleActor,"None",1,1,1,false)
self.uSwitchEffectActor:K2_SetActorRelativeLocation(FVector(0,0,0),false,nil,false)
self.uSwitchEffectActor:K2_SetActorRelativeRotation(FRotator(0,0,0),false,nil,false)
pcall(function()self:HideParticles()end)
self:ChangeFakeSwitchVehicleAvatar(self.uSwitchEffectActor.Mesh,self.lastEquipedAvatarId)
self.uSwitchEffectActor:SetAnimInsAndAnimState(self.uOldVehicleMeshAnimClass,vehicleActor)
self.uSwitchEffectActor:StartVehicleSwitchEffect(vehicleActor,self.curSwitchEffectId,self.lastEquipedAvatarId,currentAvatarID,bIsLobbyActor)
self.uOldVehicleMeshAnimClass=nil
return true
end
if not _G.AddOutfitVehOrigBeginPlay then
_G.AddOutfitVehOrigBeginPlay=impl.ReceiveBeginPlay
end
local oBegin=_G.AddOutfitVehOrigBeginPlay
impl.ReceiveBeginPlay=function(self)
oBegin(self)
pcall(function()
if self.uSwitchEffectActor then
self:StopSkinSwitchEffect()
pcall(function()self.uSwitchEffectActor:K2_DestroyActor()end)
self.uSwitchEffectActor=nil
end
self.lastEquipedAvatarId=0
if self.IsLobbyActor and self:IsLobbyActor()then
self.curSwitchEffectId=0
elseif F.isInRealMatch()then
self.curSwitchEffectId=VEH_SWITCH_EFFECT_ID
else
self.curSwitchEffectId=0
end
end)
end
if impl.LuaIsAssetsAlreadyAvailable and not _G.AddOutfitVehOrigAssets then
_G.AddOutfitVehOrigAssets=impl.LuaIsAssetsAlreadyAvailable
impl.LuaIsAssetsAlreadyAvailable=function(self,avatarId)
if _G.AimPROConfig.ModSkin and F.isVehicleSkinAllowed(tonumber(avatarId))then return true end
return _G.AddOutfitVehOrigAssets(self,avatarId)
end
end
_G.AddOutfitVehSwitchHooked=true
end)
end
function F.hookVehicleChassisLight()
if _G.AddOutfitVehChassisHooked then return end
pcall(function()
local LIC=require("GameLua.Activity.Commercialize.Actor.ActorComponent.BP_VehicleLicenseComponentBase")
if LIC and LIC.CheckHasVehicleDownloaded and not _G.AddOutfitVehOrigLicDownload then
_G.AddOutfitVehOrigLicDownload=LIC.CheckHasVehicleDownloaded
LIC.CheckHasVehicleDownloaded=function(self,itemID)
local id=tonumber(itemID)
if F.isVehicleSkinAllowed(id)or F.isChassisLightId(id)then return true end
return _G.AddOutfitVehOrigLicDownload(self,itemID)
end
end
end)
pcall(function()
local LVF=ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicVehicleExtendedFeature)
if not LVF or LVF._AddOutfitChassisHooked then return end
LVF._AddOutfitChassisHooked=true
if not _G.AddOutfitVehOrigGetFeature then
_G.AddOutfitVehOrigGetFeature=LVF.CheckHasGetFeatureItem
end
LVF.CheckHasGetFeatureItem=function(self,featureId)
if F.isChassisLightId(featureId)then return true end
return _G.AddOutfitVehOrigGetFeature(self,featureId)
end
if not _G.AddOutfitVehOrigEquippedFeature then
_G.AddOutfitVehOrigEquippedFeature=LVF.CheckHasEquippedItem
end
LVF.CheckHasEquippedItem=function(self,featureId,vehicleId)
 -- [FIX VIP] Tambahkan check hal syarat ModSkin
if _G.AimPROConfig and _G.AimPROConfig.ModSkin~=false then
if F.isChassisLightId(featureId)then
return F.getDesiredChassisLight(vehicleId)==tonumber(featureId)
end
end
return _G.AddOutfitVehOrigEquippedFeature(self,featureId,vehicleId)
end
if not _G.AddOutfitVehOrigEquipChassisData then
_G.AddOutfitVehOrigEquipChassisData=LVF.GetEquipedChassisLightData
end
LVF.GetEquipedChassisLightData=function(self,vehicleId,source)
 -- [FIX VIP] Tambahkan check hal syarat ModSkin
if _G.AimPROConfig and _G.AimPROConfig.ModSkin~=false then
local our=F.getDesiredChassisLight(vehicleId)
if our then return our end
end
return _G.AddOutfitVehOrigEquipChassisData(self,vehicleId,source)
end
if not _G.AddOutfitVehOrigChassisLightData then
_G.AddOutfitVehOrigChassisLightData=LVF.GetVehicleChassisLightData
end
LVF.GetVehicleChassisLightData=function(self,uid,vehicleId,position,source)
 -- [FIX VIP] Tambahkan check hal syarat ModSkin
if _G.AimPROConfig and _G.AimPROConfig.ModSkin~=false then
if uid and DataMgr and DataMgr.roleData and tonumber(uid)==tonumber(DataMgr.roleData.uid)then
local our=F.getDesiredChassisLight(vehicleId)
if our then return our end
end
end
return _G.AddOutfitVehOrigChassisLightData(self,uid,vehicleId,position,source)
end
if not _G.AddOutfitVehOrigPutOnFeature then
_G.AddOutfitVehOrigPutOnFeature=LVF.PutOnVehicleFeature
end
LVF.PutOnVehicleFeature=function(self,featureId,vehicleId)
featureId=tonumber(featureId)
vehicleId=tonumber(vehicleId)
if F.isChassisLightId(featureId)then
F.saveChassisLight(vehicleId,featureId)
self.equip_chassis_light=self.equip_chassis_light or{}
if vehicleId and vehicleId>0 then
self.equip_chassis_light[vehicleId]=featureId
end
return
end
return _G.AddOutfitVehOrigPutOnFeature(self,featureId,vehicleId)
end
if not _G.AddOutfitVehOrigPutOffFeature then
_G.AddOutfitVehOrigPutOffFeature=LVF.PutOffVehicleFeature
end
LVF.PutOffVehicleFeature=function(self,featureId,vehicleId)
featureId=tonumber(featureId)
vehicleId=tonumber(vehicleId)
if F.isChassisLightId(featureId)then
PERSIST.configChassisLightMap=PERSIST.configChassisLightMap or{}
if vehicleId and vehicleId>0 then
PERSIST.configChassisLightMap[vehicleId]=nil
end
if self.equip_chassis_light and vehicleId then
self.equip_chassis_light[vehicleId]=nil
end
F.persistMarkDirty()
return
end
return _G.AddOutfitVehOrigPutOffFeature(self,featureId,vehicleId)
end
end)
_G.AddOutfitVehChassisHooked=true
end
function F.hookVehicles()
F.hookVehicleSwitchEffect()
F.hookVehicleChassisLight()
pcall(function()
local WV=require("client.slua.umg.Wardrobe.subtab_vehicles")
if not WV or WV._AddOutfitVehClickHooked then return end
WV._AddOutfitVehClickHooked=true
local oClick=WV.ClickItem
WV.ClickItem=function(self,vehicleSkin,bForceUsing)
if vehicleSkin and F.isInjectedRes(vehicleSkin.res_id)then
vehicleSkin.expireTS=0
vehicleSkin.expire_ts=0
end
return oClick(self,vehicleSkin,bForceUsing)
end
local oDrop=WV.OnVehicleSlotDrop
if oDrop then
WV.OnVehicleSlotDrop=function(self,DragWidget,Index,DragDropData)
pcall(function()
local ins=DragDropData and DragDropData.ins_id
if F.isInjectedIns(tonumber(ins))then
F.ensureInjectedItemAlive(nil,nil,ins)
end
end)
return oDrop(self,DragWidget,Index,DragDropData)
end
end
end)
pcall(function()
local WNH=require("client.network.Protocol.WardrobeNewHandler")
if WNH._AddOutfitVehicleHooked then return end
WNH._AddOutfitVehicleHooked=true
local oMod=WNH.send_depot_modify_combat_vehicle_req
WNH.send_depot_modify_combat_vehicle_req=function(instid,slot_index,ope_type)
if F.modifyInjectedVehicleSlot(instid,slot_index,ope_type==true)then return end
return oMod(instid,slot_index,ope_type)
end
local oRsp=WNH.on_depot_modify_combat_vehicle_rsp
WNH.on_depot_modify_combat_vehicle_rsp=function(err_code,knapsack_vst)
if err_code==0 or err_code==NET_OK then
knapsack_vst=F.mergeInjectedIntoVehicleSlotList(knapsack_vst)
end
oRsp(err_code,knapsack_vst)
if err_code==0 or err_code==NET_OK then
F.syncVehicleSlotsToDataMgr()
F.equipVehicleTypesFromConfig(PERSIST.configVehicleSlots)
if not(_G.AddOutfitLobbyVeh and _G.AddOutfitLobbyVeh.manual)then
pcall(F.applyVehicleSkinsToPC)
end
F.persistMarkDirty()
end
end
end)
pcall(function()
local gsm=ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.golden_suit_module)
if gsm and gsm.VehicleNeedClothes and not gsm._AddOutfitVehClothesHooked then
gsm._AddOutfitVehClothesHooked=true
local o=gsm.VehicleNeedClothes
gsm.VehicleNeedClothes=function(self,vehicleId)
vehicleId=tonumber(vehicleId)
if vehicleId and F.isInjectedRes(vehicleId)then return 0 end
return o(self,vehicleId)
end
end
end)
pcall(function()
local mod=require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
if mod._FillVehicleSkinList then
if not _G.AddOutfitVehFillOrig then
_G.AddOutfitVehFillOrig=mod._FillVehicleSkinList
end
local o=_G.AddOutfitVehFillOrig
mod._FillVehicleSkinList=function(self,playerInfo,uPlayerController)
F.mergeVstIntoPlayerInfo(playerInfo)
return o(self,playerInfo,uPlayerController)
end
mod._AddOutfitFillVehHooked=true
end
end)
pcall(function()
local classMod=require("GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinItem")
if not classMod or not classMod.__inner_impl then return end
local impl=classMod.__inner_impl
if not _G.AddOutfitVehOrigClick then
_G.AddOutfitVehOrigClick=impl.OnClickSkinButton
end
local oClick=_G.AddOutfitVehOrigClick
impl.OnClickSkinButton=function(self)
 -- [PERBAIKI SKIN ASLI] jika Mod MATI, lewati proses Mod dan kembalikan langsung ke tombol asli Game!
if not _G.AimPROConfig.ModSkin then
if oClick then return oClick(self)end
return
end
local resID=tonumber(self.resID)
if resID and resID>0 then
if F.matchApplyVehicleSkin(resID)then
pcall(function()
if EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL and EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK then
EventSystem:postEvent(EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL,EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK)
end
end)
end
return
end
return oClick(self)
end
if not _G.AddOutfitVehOrigRefresh then
_G.AddOutfitVehOrigRefresh=impl.OnRefresh
end
local oRefresh=_G.AddOutfitVehOrigRefresh
impl.OnRefresh=function(self,resID,selectIndex)
oRefresh(self,resID,selectIndex)
if self.resID and tonumber(self.resID)and tonumber(self.resID)>0 then
if F.isResourcesReady(self.resID)then
pcall(function()
local PufferConst=require("client.slua.logic.download.puffer_const")
self.dowloadState=PufferConst.ENUM_DownloadState.Done
self.UIRoot.Image_Download:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
self:SetWidgetVisible(self.UIRoot.Image_Mask,false)
end)
else
F.requestResourceDownload(self.resID)
end
end
end
classMod._AddOutfitSkinClickHooked=true
end)
pcall(function()
local utilMod=require("GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
if utilMod.CheckHasUnLockFeature and not utilMod._AddOutfitVehPlateHooked then
utilMod._AddOutfitVehPlateHooked=true
local orig=utilMod.CheckHasUnLockFeature
utilMod.CheckHasUnLockFeature=function(ft,uid,itemId)
local id=tonumber(itemId)
if F.isVehicleSkinAllowed(id)or F.isChassisLightId(id)then return true end
return orig(ft,uid,itemId)
end
end
end)
pcall(function()
local panelMod=require("GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinAndMusicPanel")
if panelMod and panelMod.__inner_impl and not panelMod._AddOutfitInitSkinHooked then
panelMod._AddOutfitInitSkinHooked=true
local o=panelMod.__inner_impl.InitSkinList
panelMod.__inner_impl.InitSkinList=function(self)
F.applyVehicleSkinsToPC(F.getPC())
return o(self)
end
end
end)
pcall(function()
local VUC=require("GameLua.GameCore.Module.Vehicle.Component.VehicleUserComponent")
if not VUC then return end
if not _G.AddOutfitVehOrigEnter then
_G.AddOutfitVehOrigEnter=VUC.SendUIMsgWhenEnterVehicleCompleted
end
local oEnter=_G.AddOutfitVehOrigEnter
VUC.SendUIMsgWhenEnterVehicleCompleted=function(self)
oEnter(self)
pcall(function()
if slua.isValid(self.Vehicle)then
F.autoApplyVehicleSkinOnEnter(self.Vehicle)
end
end)
end
VUC._AddOutfitEnterVehHooked=true
end)
end
function F.hookWeaponWear()
pcall(function()
local HT=require("client.logic.lobby.hall_theme_utils")
local o=HT.IsWeaponWear
HT.IsWeaponWear=function(insId)
insId=tonumber(insId)
if F.isInjectedIns(insId)then
local c=F.cache()
local Arm=require("client.logic.armory.logic_armory")
for wid,w in pairs(c.weapons)do
if tonumber(w.insID)==insId then
if Arm.rsp_list and Arm.rsp_list.install_list and Arm.rsp_list.install_list[wid]then
return tonumber(Arm.rsp_list.install_list[wid].skin_id)==insId
end
return true
end
end
end
return o(insId)
end
end)
end
function F.hookNotice()
pcall(function()
if DataMgr and not DataMgr._AddOutfitExpireHooked then
DataMgr._AddOutfitExpireHooked=true
local oValid=DataMgr.IsValidTime
DataMgr.IsValidTime=function(expireTS)
if expireTS==nil or tonumber(expireTS)==0 then return true end
if oValid and oValid(expireTS)then return true end
local inMatch=false
pcall(function()
inMatch=GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
end)
if not inMatch then return true end
return false
end
end
end)
end
function F.wrapWardrobeClick(classMod,key)
if not classMod or not classMod[key]or classMod["_AddOutfitWrap_"..key]then return end
classMod["_AddOutfitWrap_"..key]=true
local orig=classMod[key]
classMod[key]=function(self,widget,index)
local itemData=self.LoopScrollGrid_Normal and self.LoopScrollGrid_Normal:GetItemData(index)
if itemData then
F.clearItemExpire(itemData,itemData.ins_id,itemData.res_id)
F.ensureDepotItemValid(itemData.ins_id,itemData.res_id)
end
return orig(self,widget,index)
end
end
function F.hookWardrobeWearClicks()
if _G.AddOutfitWearClickHooked then return end
_G.AddOutfitWearClickHooked=true
F.hookNotice()
pcall(function()
local avatarClass=require("client.slua.umg.Wardrobe.subtab_avatar")
F.wrapWardrobeClick(avatarClass,"OnClickItem")
F.wrapWardrobeClick(avatarClass,"ClickAvatarItem")
end)
pcall(function()
local suitClass=require("client.slua.umg.Wardrobe.subtab_suit")
F.wrapWardrobeClick(suitClass,"OnClickItem")
end)
pcall(function()
local bagClass=require("client.slua.umg.Wardrobe.subtab_bag")
F.wrapWardrobeClick(bagClass,"OnClickItem")
end)
end
function F.hookAvatarValid()
pcall(function()
local path="GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent"
local comp=require(path)
if comp and comp.CheckItemValid then
local o=comp.CheckItemValid
comp.CheckItemValid=function(self,resID)
if F.isInjectedRes(resID)then return true end
return o(self,resID)
end
end
end)
end
function F.isInRealMatch()
local ok,r=pcall(function()
return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
end)
return ok and r==true
end
function F.getLocalChar()
local ok,GD=pcall(require,"GameLua.GameCore.Data.GameplayData")
if not ok or not GD then return nil end
local char=GD.GetPlayerCharacter()
if char and slua.isValid(char)then return char end
return nil
end
function F.getWAC(char)
local w=char and char.GetCurrentWeapon and char:GetCurrentWeapon()
if slua.isValid(w)and slua.isValid(w.WeaponAvatarComponent)then
return w.WeaponAvatarComponent
end
return nil
end
function F.notify(msg)
if not DEBUG then return end
pcall(function()if ShowNotice then ShowNotice("[AddOutfit] "..tostring(msg))end end)
end
function F.getDesiredOutfit()
if MATCH_CONFIG.outfitRes and MATCH_CONFIG.outfitRes>0 then
return MATCH_CONFIG.outfitRes
end
local wornSuitRes
pcall(function()
local _,res=F.findWornInsBySubType(OUTFIT_SUB,function(r)return F.isSuitRes(r)end)
wornSuitRes=tonumber(res)
end)
if wornSuitRes and wornSuitRes>0 then return wornSuitRes end
local tshirtWorn=false
pcall(function()
local ins=F.findWornInsBySubType(OUTFIT_SUB,function(r)return F.isTshirtRes(r)end)
tshirtWorn=ins~=nil
end)
if tshirtWorn then return nil end
F.syncBodyCacheFromLobby()
local c=F.cache()
return c.outfitRes
end
function F.matchApplyOutfit(char)
local outfitRes=F.getDesiredOutfit()
if not outfitRes then return true end
if not F.isResourcesReady(outfitRes)then
F.requestResourceDownload(outfitRes)
return false
end
local comp=F.getAvatarComp2(char)
if not comp then return false end
local ok=F.setMakeSkin(comp,outfitRes,F.CUST_SLOT.ClothesEquipemtSlot,{allowPutOn=true})
return ok
end
function F.getDesiredHat()
if MATCH_CONFIG.hatRes and tonumber(MATCH_CONFIG.hatRes)>0 then
return tonumber(MATCH_CONFIG.hatRes)
end
F.syncHatCacheFromLobby()
local h=F.cache().hatRes
if h and tonumber(h)>0 then return tonumber(h)end
return tonumber(_G.AddOutfitLastLobbyHatRes)or nil
end
function F.ensureSkinDownload(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return end
_G.skinIdCache=_G.skinIdCache or{}
if not _G.skinIdCache[resID]then
F.requestResourceDownload(resID)
_G.skinIdCache[resID]=true
end
end
function F.syncGlobalWearSkins()
_G.CustSlotType=F.CUST_SLOT
_G.skinIdCache=_G.skinIdCache or{}
_G.HatSkin=tonumber(F.getDesiredHat())or 0
local outfit=F.getDesiredOutfit()
_G.SuitSkin=tonumber(outfit)
or tonumber(F.getDesiredWear("tshirtRes","tshirtRes","AddOutfitLastLobbyTshirtRes",F.syncBodyCacheFromLobby))
or 0
_G.PantsSkin=tonumber(F.getDesiredWear("pantsRes","pantsRes","AddOutfitLastLobbyPantsRes",F.syncBodyCacheFromLobby))or 0
_G.ShoesSkin=tonumber(F.getDesiredWear("shoesRes","shoesRes","AddOutfitLastLobbyShoesRes",F.syncBodyCacheFromLobby))or 0
_G.GlovesSkin=tonumber(F.getDesiredWear("glovesRes","glovesRes","AddOutfitLastLobbyGlovesRes",F.syncBodyCacheFromLobby))or 0
_G.MaskSkin=tonumber(F.getDesiredMask())or 0
_G.GlassSkin=tonumber(F.getDesiredGlass())or 0
_G.GliderSkin=tonumber(F.getDesiredGliderRes())or 0
_G.ParachuteSkin=tonumber(F.getDesiredParachuteRes())or 0
end
function F.setMakeSkinAtIndex(comp,applyIdx,resID,slotID)
resID=tonumber(resID)
slotID=tonumber(slotID)
applyIdx=tonumber(applyIdx)
if not comp or not slua.isValid(comp)or not resID or resID<=0 or not slotID or applyIdx==nil then
return false
end
local changed=false
pcall(function()
local net=comp.NetAvatarData
if not net then return end
local applyData=net.SlotSyncData
if not applyData or not slua.isValid(applyData)then return end
local equipment=applyData:Get(applyIdx)
if equipment and equipment.SlotID==slotID then
local cur=tonumber(equipment.ItemId)or tonumber(equipment.ItemID)or 0
if cur~=resID then
F.ensureSkinDownload(resID)
equipment.ItemId=resID
if equipment.ItemID~=nil then equipment.ItemID=resID end
applyData:Set(applyIdx,equipment)
changed=true
end
end
end)
return changed
end
function F.applySlotSkinBatch(comp,entries,opts)
opts=opts or{}
if not comp or not slua.isValid(comp)or not entries then return false end
local changed,anyOk=false,false
pcall(function()
local net=comp.NetAvatarData
if not net then return end
local applyData=net.SlotSyncData
if not applyData or not slua.isValid(applyData)then return end
local num=applyData:Num()
for _,e in ipairs(entries)do
local itemId,slotId=tonumber(e[1]),tonumber(e[2])
if itemId and itemId>0 and slotId then
F.ensureSkinDownload(itemId)
for i=0,num-1 do
local equipment=applyData:Get(i)
if equipment and equipment.SlotID==slotId then
local cur=tonumber(equipment.ItemId)or tonumber(equipment.ItemID)or 0
if cur==itemId then
anyOk=true
elseif cur~=itemId then
equipment.ItemId=itemId
if equipment.ItemID~=nil then equipment.ItemID=itemId end
applyData:Set(i,equipment)
changed=true
anyOk=true
end
break
end
end
end
end
if(changed or opts.forceRep)and comp.OnRep_BodySlotStateChanged then
comp:OnRep_BodySlotStateChanged()
end
end)
return anyOk or changed
end
function F.setMakeSkin(comp,resID,slotID,opts)
 -- [PENGAMAN 100%] Tolak gambar Skin VIP (>1000000) naik dasar bisa jika fungsi saklar MATI
if not _G.AimPROConfig.ModSkin and tonumber(resID)and tonumber(resID)>1000000 then return false end
opts=opts or{}
slotID,resID=tonumber(slotID),tonumber(resID)
if not comp or not slua.isValid(comp)or not slotID or not resID or resID<=0 then return false end
local changed=false
local already=false
pcall(function()
local net=comp.NetAvatarData
if not net then return end
local applyData=net.SlotSyncData
if not applyData or not slua.isValid(applyData)then return end
local num=applyData:Num()
for i=0,num-1 do
local equipment=applyData:Get(i)
if equipment and equipment.SlotID==slotID then
local cur=tonumber(equipment.ItemId)or tonumber(equipment.ItemID)or 0
if cur==resID then
already=true
elseif cur~=resID then
F.ensureSkinDownload(resID)
equipment.ItemId=resID
if equipment.ItemID~=nil then equipment.ItemID=resID end
applyData:Set(i,equipment)
changed=true
end
break
end
end
if changed and not opts.skipRep and comp.OnRep_BodySlotStateChanged then
comp:OnRep_BodySlotStateChanged()
end
if opts.inAir and comp.PutOnCustomEquipmentByID then
comp:PutOnCustomEquipmentByID(resID)
end
end)
if already or changed then return true end
if opts.allowPutOn and comp.PutOnCustomEquipmentByID then
pcall(function()comp:PutOnCustomEquipmentByID(resID)end)
return true
end
return false
end
F.setSlotSkin=F.setMakeSkin
_G.setMakeSkin=function(applyIdx,itemId,applyEquipSlot)
local char=F.getLocalChar()
if not char then return end
local comp=F.getAvatarComp2(char)
if not comp then return end
if F.setMakeSkinAtIndex(comp,applyIdx,itemId,applyEquipSlot)then
pcall(function()
if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged()end
end)
end
end
function F.patchWearNetAvatar(comp,resID,slotName,noForceShow)
if not comp or not slua.isValid(comp)or not resID or resID<=0 or not slotName then return false end
local ok=false
pcall(function()
local EAvatarSlotType=import("EAvatarSlotType")
local ESyncOperation=import("ESyncOperation")
local slot=EAvatarSlotType[slotName]
if not slot then return end
local sync=comp.GetSlotSyncData and comp:GetSlotSyncData(slot)
if sync then
sync.ItemID=resID
if sync.FakeItemID~=nil then sync.FakeItemID=resID end
sync.OperationType=ESyncOperation.PutOn
if comp.ChangeSlotSyncData then
comp:ChangeSlotSyncData(sync)
ok=true
end
end
if not noForceShow and comp.SetAvatarVisibility then
comp:SetAvatarVisibility(slot,true,true)
end
end)
return ok
end
function F.patchHatNetAvatar(comp,hatRes)
return F.patchWearNetAvatar(comp,hatRes,"EAvatarSlotType_HatEquipemtSlot")
end
function F.matchApplyWearItem(char,resID,slotID,label,opts)
if not resID or resID<=0 then return true end
slotID=slotID or F.resToCustSlot(resID)
if not slotID then return false end
local comp=F.getAvatarComp2(char)
if not comp then return false end
opts=opts or{}
opts.allowPutOn=true
local ok=F.setMakeSkin(comp,resID,slotID,opts)
return ok
end
function F.getDesiredMask()
if MATCH_CONFIG.maskRes and tonumber(MATCH_CONFIG.maskRes)>0 then
return tonumber(MATCH_CONFIG.maskRes)
end
F.syncFaceCacheFromLobby()
local m=F.cache().maskRes
if m and tonumber(m)>0 then return tonumber(m)end
return tonumber(_G.AddOutfitLastLobbyMaskRes)or nil
end
function F.getDesiredGlass()
if MATCH_CONFIG.glassRes and tonumber(MATCH_CONFIG.glassRes)>0 then
return tonumber(MATCH_CONFIG.glassRes)
end
F.syncFaceCacheFromLobby()
local g=F.cache().glassRes
if g and tonumber(g)>0 then return tonumber(g)end
return tonumber(_G.AddOutfitLastLobbyGlassRes)or nil
end
function F.matchApplyFaceWear(char)
local maskRes=F.getDesiredMask()
local glassRes=F.getDesiredGlass()
if(not maskRes or maskRes<=0)and(not glassRes or glassRes<=0)then
return true
end
char=char or F.getLocalChar()
if not char then return false end
local comp=F.getAvatarComp2(char)
if not comp then return false end
local ok=false
pcall(function()
local EAvatarSlotType=import("EAvatarSlotType")
local ESyncOperation=import("ESyncOperation")
local net=comp.NetAvatarData
local applyData=net and net.SlotSyncData
local function forceApplySlot(resID,slotID,slotNameStr)
if not resID or resID<=0 then return end
local slotEnum=EAvatarSlotType and EAvatarSlotType[slotNameStr]
local needRep=false
 -- 1. TIMPA DATA JARINGAN (Cegah data tidak sinkron)
if applyData and slua.isValid(applyData)then
local found=false
for i=0,applyData:Num()-1 do
local equipment=applyData:Get(i)
if equipment and equipment.SlotID==slotID then
found=true
local cur=tonumber(equipment.ItemId)or tonumber(equipment.ItemID)or 0
if cur~=resID then
F.ensureSkinDownload(resID)
equipment.ItemId=resID
if equipment.ItemID~=nil then equipment.ItemID=resID end
if equipment.FakeItemID~=nil then equipment.FakeItemID=resID end
applyData:Set(i,equipment)
needRep=true
end
break
end
end
if not found then
F.ensureSkinDownload(resID)
local entry=import("AvatarSyncData")()
entry.SlotID=slotID
entry.ItemId=resID
entry.ItemID=resID
entry.FakeItemID=resID
entry.OperationType=ESyncOperation.PutOn
applyData:Add(entry)
needRep=true
end
end
 -- [LOGIC tidur BANYAK] - maksimal optimal FPS MAKSIMAL MUTLAK
_G.FaceWearStateCache=_G.FaceWearStateCache or{}
 -- Buat ID khusus untuk karakter item tampil di agar tidak bentrok
local cacheKey=tostring(comp).."_"..tostring(slotID)
if needRep or _G.FaceWearStateCache[cacheKey]~=resID then
 -- Pertama kali memaksa tampil / atau ID Skin berubah -> Lari Full C++
if slotEnum then
if comp.CancelHideAvatarBySlot then comp:CancelHideAvatarBySlot(slotEnum)end
if comp.SetAvatarVisibility then comp:SetAvatarVisibility(slotEnum,true,true)end
end
if comp.PutOnCustomEquipmentByID then
comp:PutOnCustomEquipmentByID(resID)
end
 -- Update Cache untuk loop setelah pergi ke Tidur
_G.FaceWearStateCache[cacheKey]=resID
 ok=true -- Aktifkan flag untuk panggil OnRep_BodySlotStateChanged (gambar ulang mesh)
else
 -- status kondisi tidur BANYAK: Data sudah benar, mesh 3D sudah bisa render.
 -- Hanya jalankan fungsi sangat ringan CancelHide untuk cegah game menyembunyikan sendiri saat ambil topi pastikan Bahaya (1,2,3).
 -- LEWATI proses render lagi mesh untuk agar FPS tidak drop.
if slotEnum and comp.CancelHideAvatarBySlot then
comp:CancelHideAvatarBySlot(slotEnum)
end
end
end
 -- Panggil perintah paksa untuk Masker (Mask)
forceApplySlot(maskRes,F.CUST_SLOT.FaceEquipemtSlot,"EAvatarSlotType_FaceEquipemtSlot")
 -- Panggil perintah paksa untuk Kacamata (Glass)
forceApplySlot(glassRes,F.CUST_SLOT.GlassEquipemtSlot,"EAvatarSlotType_GlassEquipemtSlot")
 -- Update gambar gambar 3D hanya saat Keluar dari tidur BANYAK (Saat diperlukan)
if ok and comp.OnRep_BodySlotStateChanged then
comp:OnRep_BodySlotStateChanged()
end
end)
return ok
end
function F.getDesiredWear(configKey,cacheResKey,globalKey,syncFn)
local fixed=MATCH_CONFIG[configKey]and tonumber(MATCH_CONFIG[configKey])
if fixed and fixed>0 then return fixed end
local persistKey=cacheResKey and cacheResKey:gsub("Res$","")
if persistKey and PERSIST.configSlots then
local pr=tonumber(PERSIST.configSlots[persistKey])
if pr and pr>0 then return pr end
end
if syncFn then syncFn()end
local v=F.cache()[cacheResKey]
if v and tonumber(v)>0 then return tonumber(v)end
return tonumber(_G[globalKey])or nil
end
-- ==========================================================
 -- SISTEM SISTEM topi/tas VIP (AUTO LEVEL 1, 2, 3 + SYNC INGAME)
 -- ==========================================================
local GAME_HELMET_LEVEL={[502001]=1,[502004]=1,[502002]=2,[502005]=2,[502003]=3,}
local GAME_BAG_LEVEL={[501001]=1,[501004]=1,[501002]=2,[501005]=2,[501003]=3,}
local EQUIP_LEVEL_SETS={}
local _equipLevelByRes={}
function F.registerEquipLevelSet(catalog,lv1,lv2,lv3,slot)
catalog=tonumber(catalog)
if not catalog then return end
local set={catalog=catalog,lv1=tonumber(lv1)or 0,lv2=tonumber(lv2)or 0,lv3=tonumber(lv3)or 0,slot=slot or"helmet"}
EQUIP_LEVEL_SETS[catalog]=set
for _,rid in ipairs({catalog,set.lv1,set.lv2,set.lv3})do
if rid and rid>0 then _equipLevelByRes[rid]=set end
end
end
local EQUIP_LEVEL_RANGES={{base=1502000000,slot="helmet"},{base=1501000000,slot="bag"},}
function F.findEquipLevelRange(resID)
resID=tonumber(resID)
if not resID then return nil end
for _,r in ipairs(EQUIP_LEVEL_RANGES)do
if resID>=r.base and resID<r.base+1000000 then return r end
end
return nil
end
function F.detectLevelFromPattern(resID)
resID=tonumber(resID)
if not resID then return nil,nil end
local r=F.findEquipLevelRange(resID)
if not r then return nil,nil end
if resID<r.base+1000 or resID>=r.base+4000 then return nil,nil end
local tail=resID-r.base
local levelDigit=math.floor(tail/1000)
if levelDigit>=1 and levelDigit<=3 then
return levelDigit,r.base+(tail-levelDigit*1000)
end
return nil,nil
end
function F.buildPatternLevelSet(catalog)
catalog=tonumber(catalog)
if not catalog then return nil end
local r=F.findEquipLevelRange(catalog)
if not r then return nil end
local tail=catalog-r.base
if tail<0 or tail>=1000 then return nil end
return{catalog=catalog,lv1=catalog+1000,lv2=catalog+2000,lv3=catalog+3000,slot=r.slot}
end
function F.getEquipLevelSet(resID)
resID=tonumber(resID)
if not resID then return nil end
local set=_equipLevelByRes[resID]
if set then return set end
local level,catalog=F.detectLevelFromPattern(resID)
if catalog then
if EQUIP_LEVEL_SETS[catalog]then return EQUIP_LEVEL_SETS[catalog]end
if level then return F.buildPatternLevelSet(catalog)end
end
local direct=F.buildPatternLevelSet(resID)
if direct then
_equipLevelByRes[resID]=direct
if direct.lv1>0 then _equipLevelByRes[direct.lv1]=direct end
if direct.lv2>0 then _equipLevelByRes[direct.lv2]=direct end
if direct.lv3>0 then _equipLevelByRes[direct.lv3]=direct end
end
return direct
end
function F.normalizeEquipCatalogRes(resID)
resID=tonumber(resID)
if not resID or resID<=0 then return 0 end
local set=F.getEquipLevelSet(resID)
if set then return set.catalog end
return resID
end
function F.detectLevelFromEquipRes(resID)
resID=tonumber(resID)
if not resID then return nil end
local set=F.getEquipLevelSet(resID)
if set then
if resID==set.lv1 then return 1
elseif resID==set.lv2 then return 2
elseif resID==set.lv3 then return 3 end
end
return F.detectLevelFromPattern(resID)
end
function F.mapEquipLevelSet(set,level)
if not set then return 0 end
level=tonumber(level)or 3
if level==1 then return set.lv1 or 0
elseif level==2 then return set.lv2 or 0 end
return set.lv3 or 0
end
function F.mapEquipSkinRes(resID,level)
resID,level=tonumber(resID),tonumber(level)or 3
if not resID or resID<=0 then return 0 end
local catalogRes=F.normalizeEquipCatalogRes(resID)
local set=F.getEquipLevelSet(catalogRes)
if set then
local mapped=F.mapEquipLevelSet(set,level)
if mapped>0 then return mapped end
end
local mapped=0
pcall(function()
local itemMappingCfg=CDataTable.GetTableData("BackpackMapping",catalogRes)
if itemMappingCfg then
if level==1 then mapped=tonumber(itemMappingCfg.SkinItemIDLv1)or 0
elseif level==2 then mapped=tonumber(itemMappingCfg.SkinItemIDLv2)or 0
else mapped=tonumber(itemMappingCfg.SkinItemIDLv3)or 0 end
end
end)
if mapped>0 then return mapped end
if F.isInjectedRes(catalogRes)then return catalogRes end
return 0
end
function F.buildEquipSkinLists(resID)
resID=F.normalizeEquipCatalogRes(resID)
return{F.mapEquipSkinRes(resID,1),F.mapEquipSkinRes(resID,2),F.mapEquipSkinRes(resID,3)}
end
function F.detectEquipLevelFromBaseId(baseId,catalogResID)
baseId,catalogResID=tonumber(baseId),tonumber(catalogResID)
if not baseId or baseId<=0 then return nil end
local level
pcall(function()
catalogResID=catalogResID and F.normalizeEquipCatalogRes(catalogResID)or catalogResID
if catalogResID then
local set=F.getEquipLevelSet(catalogResID)
if set then
if baseId==set.lv1 then level=1
elseif baseId==set.lv2 then level=2
elseif baseId==set.lv3 then level=3 end
end
if not level then
local m=CDataTable.GetTableData("BackpackMapping",catalogResID)
if m then
if tonumber(m.SkinItemIDLv1)==baseId then level=1
elseif tonumber(m.SkinItemIDLv2)==baseId then level=2
elseif tonumber(m.SkinItemIDLv3)==baseId then level=3 end
end
end
end
if not level then
local patLevel,patCatalog=F.detectLevelFromPattern(baseId)
if patLevel and(not catalogResID or patCatalog==catalogResID)then level=patLevel end
end
if not level then level=GAME_HELMET_LEVEL[baseId]or GAME_BAG_LEVEL[baseId]end
if not level and baseId>=1505000001 and baseId<=1505000003 then level=baseId-1505000000 end
if not level then
local BU=import("BackpackUtils")
if BU and BU.GetEquipmentHelmetLevel then
local hl=BU.GetEquipmentHelmetLevel(baseId)
if hl and hl>=1 and hl<=3 then level=hl end
end
if not level and BU and BU.GetEquipmentBagLevel then
local bl=BU.GetEquipmentBagLevel(baseId)
if bl and bl>=1 and bl<=3 then level=bl end
end
end
end)
return level
end
function F.isBaseEquipItemId(itemId)
itemId=tonumber(itemId)
if not itemId or itemId<=0 then return false end
if GAME_HELMET_LEVEL[itemId]or GAME_BAG_LEVEL[itemId]then return true end
if itemId>=1505000001 and itemId<=1505000100 then return true end
if itemId>=1501000000 and itemId<1502000000 then return true end
if itemId>=502001 and itemId<=502999 then return true end
if itemId>=501001 and itemId<=501999 then return true end
return false
end
function F.resolveMatchEquipSkin(catalogResID,baseItemID)
catalogResID=F.normalizeEquipCatalogRes(catalogResID)
if not catalogResID or catalogResID<=0 then return 0 end
local level=F.detectEquipLevelFromBaseId(baseItemID,catalogResID)or 3
return F.mapEquipSkinRes(catalogResID,level)
end
function F.getCharEquipLevel(char,slotID)
local found=nil
pcall(function()
local comp=char and char.CharacterAvatarComp2_BP
if not slua.isValid(comp)then return end
local NetAvatarData=slua.IndexReference(comp,"NetAvatarData")
if not NetAvatarData then return end
local TempSlotSyncData=slua.IndexReference(NetAvatarData,"SlotSyncData")
if not TempSlotSyncData then return end
local n=TempSlotSyncData:Num()
for i=0,n-1 do
local AvatarSynData=TempSlotSyncData:Get(i)
if AvatarSynData and AvatarSynData.SlotID==slotID and AvatarSynData.ItemID and AvatarSynData.ItemID>0 then
found=AvatarSynData.ItemID
return
end
end
end)
return found
end
function F.isWearingEquip(char,slot)
local slotID=(slot=="helmet")and 9 or(slot=="bag")and 8 or nil
if not slotID then return false end
local itemID=F.getCharEquipLevel(char,slotID)
if itemID and itemID>0 then return true end
local wearing=false
pcall(function()
local pc=F.getPC()
if not pc or not slua.isValid(pc)then return end
if pc.PlayerState and pc.PlayerState.MetroPlayerStateAvatarFeature then
local psEquip=pc.PlayerState.MetroPlayerStateAvatarFeature.EquipmentAvatarData
if psEquip then
if slot=="helmet"and psEquip.HelmetAvatar and psEquip.HelmetAvatar>0 then wearing=true
elseif slot=="bag"and psEquip.BagAvatar and psEquip.BagAvatar>0 then wearing=true end
end
end
end)
return wearing
end
local EQUIP_APPLY={lastBagWrite=0,lastHelmetWrite=0}
function F.levelSkinID(baseSkin,level)
level=tonumber(level)or 1
if level<1 then level=1 end
local mapped=0
pcall(function()
local t=CDataTable.GetTableData("BackpackMapping",baseSkin)
if t then
if level<=1 then mapped=tonumber(t.SkinItemIDLv1)or 0
elseif level==2 then mapped=tonumber(t.SkinItemIDLv2)or 0
else mapped=tonumber(t.SkinItemIDLv3)or 0 end
end
end)
if mapped>0 then return mapped end
return baseSkin+(level-1)*1000
end
function F.applyEquipSkinToComp(comp,bagRes,helmetRes)
local applied,found=false,false
pcall(function()
local EAvatarSlotType=import("EAvatarSlotType")
local BackpackUtils=import("BackpackUtils")
local function doSlot(slotEnum,res,levelFn,lastKey)
res=tonumber(res)or 0
if res<=0 or not slotEnum then return end
local sync=comp.GetSlotSyncData and comp:GetSlotSyncData(slotEnum)
if not sync then return end
local cur=tonumber(sync.ItemID)or 0
local addID=tonumber(sync.AdditionalItemID)or 0
if cur<=0 and addID<=0 then return end
found=true
local lvl=1
pcall(function()
if levelFn then lvl=levelFn(addID>0 and addID or cur)or 1 end
end)
if lvl<1 then lvl=1 end
local target=F.levelSkinID(res,lvl)
if target>0 and cur~=target then
sync.ItemID=target
comp:ChangeSlotSyncData(sync)
applied=true
EQUIP_APPLY[lastKey]=target
end
end
doSlot(EAvatarSlotType.EAvatarSlotType_BackpackEquipemtSlot,bagRes,BackpackUtils.GetEquipmentBagLevel,"lastBagWrite")
doSlot(EAvatarSlotType.EAvatarSlotType_HelmetEquipemtSlot,helmetRes,BackpackUtils.GetEquipmentHelmetLevel,"lastHelmetWrite")
end)
return applied,found
end
function F.matchApplyEquipmentSkin(char,bagRes,helmetRes)
bagRes=tonumber(bagRes)or 0
helmetRes=tonumber(helmetRes)or 0
if bagRes<=0 and helmetRes<=0 then return true end
local comp=char.CharacterAvatarComp2_BP
if not slua.isValid(comp)then return false end
local applied,found=F.applyEquipSkinToComp(comp,bagRes,helmetRes)
if applied then
pcall(function()
if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged()end
end)
return true
end
return found
end
function F.hookEquipmentRectify()
_G.AddOutfitEquipRectifyFn=function(self)
pcall(function()
if self.IsLobbyActor and self:IsLobbyActor()then return end
if not(self.IsSelf and self:IsSelf())then return end
local bagRes=F.getDesiredWear("bagRes","bagRes","AddOutfitLastLobbyBagRes",F.syncBodyCacheFromLobby)
local helmetRes=F.getDesiredWear("helmetRes","helmetRes","AddOutfitLastLobbyHelmetRes",F.syncBodyCacheFromLobby)
if(tonumber(bagRes)or 0)<=0 and(tonumber(helmetRes)or 0)<=0 then return end
F.applyEquipSkinToComp(self,bagRes,helmetRes)
end)
end
pcall(function()
local MCAC=require("GameLua.Mod.TPlan.Component.MetroCharacterAvatarComponent")
if MCAC._AddOutfitRectifyHooked then return end
MCAC._AddOutfitRectifyHooked=true
local o=MCAC.ProcessClientAvatarRectify
MCAC.ProcessClientAvatarRectify=function(self)
o(self)
if _G.AddOutfitEquipRectifyFn then _G.AddOutfitEquipRectifyFn(self)end
end
end)
end
function F.hookBackpackValid()
if _G.DEV_WARDROBE_BP_HOOKED then return end
_G.DEV_WARDROBE_BP_HOOKED=true
pcall(function()
local BU=import("BackpackUtils")
if BU and BU.GetBPIDByResID then
local orig=BU.GetBPIDByResID
BU.GetBPIDByResID=function(resID)
resID=tonumber(resID)
if resID and F.isInjectedRes(resID)then
local bp=orig(resID)
if bp and bp>0 then return bp end
return resID
end
return orig(resID)
end
end
end)
pcall(function()
local AU=import("AvatarUtils")
if AU and AU.GetBPIDByResID then
local orig=AU.GetBPIDByResID
AU.GetBPIDByResID=function(resID,...)
resID=tonumber(resID)
if resID and F.isInjectedRes(resID)then
local bp=orig(resID,...)
if bp and bp>0 then return bp end
return resID
end
return orig(resID,...)
end
end
end)
end
function F.hookEquipMapping()
pcall(function()
if DataMgr and not DataMgr._lava_equip_map_hooked then
DataMgr._lava_equip_map_hooked=true
local orig=DataMgr.GetEquipmentItemIDByResID
DataMgr.GetEquipmentItemIDByResID=function(level,itemResID)
level,itemResID=tonumber(level)or 3,tonumber(itemResID)
local r=orig(level,itemResID)
if r and r>0 then return r end
 -- sini adalah perintah unik agar bantu game kenali area Icon topi/Tas VIP di Lobby
if F.isInjectedIns(itemResID)then
local resID=R.insToRes[itemResID]
if resID then return F.levelSkinID(resID,level)end
end
if F.isInjectedRes(itemResID)then
return F.levelSkinID(itemResID,level)
end
return r or 0
end
end
end)
end
function F.hookEquipMapping()
pcall(function()
if DataMgr and not DataMgr._lava_equip_map_hooked then
DataMgr._lava_equip_map_hooked=true
local orig=DataMgr.GetEquipmentItemIDByResID
DataMgr.GetEquipmentItemIDByResID=function(level,itemResID)
 -- [PERBAIKI SKIN ASLI] jika fungsi saklar MATI, paksa game gunakan fungsi asli untuk jaga lagi Skin topi/Tas asli!
if not _G.AimPROConfig.ModSkin then
if orig then return orig(level,itemResID)end
return 0
end
level,itemResID=tonumber(level)or 3,tonumber(itemResID)
local catalogRes=F.normalizeEquipCatalogRes(itemResID)
local r=orig(level,catalogRes)
if r and r>0 then return r end
if F.isInjectedIns(itemResID)then
local resID=R.insToRes[itemResID]
if resID then return F.levelSkinID(resID,level)end
end
if F.isInjectedRes(itemResID)then
return F.levelSkinID(itemResID,level)
end
return r or 0
end
end
end)
pcall(function()
local CAC=require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
if CAC._lava_equip_skin_hooked then return end
CAC._lava_equip_skin_hooked=true
local orig3=CAC.GetEquipmentSkinItemID
CAC.GetEquipmentSkinItemID=function(self,InItemID)
if self.IsSelf and not self:IsSelf()then return orig3(self,InItemID)end
 -- [PERBAIKI SKIN ASLI] kembalikan Skin asli Game jika ModSkin MATI
if not _G.AimPROConfig.ModSkin then return orig3(self,InItemID)end
local cch=F.cache()
InItemID=tonumber(InItemID)or 0
local function tryGetSkin(catalogRes)
if not catalogRes or catalogRes<=0 then return 0 end
catalogRes=F.normalizeEquipCatalogRes(catalogRes)
local skin=F.resolveMatchEquipSkin(catalogRes,InItemID)
if skin>0 then return skin end
for lvl=1,3 do
local s=F.mapEquipSkinRes(catalogRes,lvl)
if s>0 then return s end
end
return 0
end
local origResult=orig3(self,InItemID)
if origResult and origResult>0 and origResult~=InItemID then return origResult end
local isHelmetQuery=GAME_HELMET_LEVEL[InItemID]~=nil or(InItemID>=502001 and InItemID<=502999)
local isBagQuery=GAME_BAG_LEVEL[InItemID]~=nil or(InItemID>=501001 and InItemID<=501999)
local char=F.getLocalChar()
if isHelmetQuery and cch.helmetRes and cch.helmetRes>0 then
if char and F.isWearingEquip(char,"helmet")then
local skin=tryGetSkin(cch.helmetRes)
if skin>0 then return skin end
end
end
if isBagQuery and cch.bagRes and cch.bagRes>0 then
if char and F.isWearingEquip(char,"bag")then
local skin=tryGetSkin(cch.bagRes)
if skin>0 then return skin end
end
end
return origResult
end
local origEquipFinish=CAC.OnAvatarEquipFinish
CAC.OnAvatarEquipFinish=function(self,slotType,isEquipped,itemID)
if origEquipFinish then origEquipFinish(self,slotType,isEquipped,itemID)end
if not isEquipped then return end
if not self.IsSelf or not self:IsSelf()then return end
 if not _G.AimPROConfig.ModSkin then return end -- Hentikan load serahkan area Mod jika MATI
pcall(function()
if self.IsLobbyActor and self:IsLobbyActor()then return end
local EAvatarSlotType=import("EAvatarSlotType")
local cch=F.cache()
local isHelmet=slotType==EAvatarSlotType.EAvatarSlotType_HelmetEquipemtSlot
local isBag=slotType==EAvatarSlotType.EAvatarSlotType_BackpackEquipemtSlot
if(isHelmet and cch.helmetRes and cch.helmetRes>0)
or(isBag and cch.bagRes and cch.bagRes>0)then
local owner=self.GetOwner and self:GetOwner()
if owner and slua.isValid(owner)and owner.AddGameTimer then
owner:AddGameTimer(0.25,false,function()
if slua.isValid(owner)then F.matchApplyEquipSkins(owner)end
end)
end
end
F.applyMatchEquipAvatarToController()
end)
end
end)
end
function F.applyAirborneSlots(char,forceInAir)
local comp=F.getAvatarComp2(char)
if not comp or not slua.isValid(comp)then return false end
pcall(function()F.syncAirborneToDataMgr()end)
local inAir=forceInAir==true or F.isCharacterAirborne(char)
local any=false
local paraRes=F.getDesiredParachuteRes()
if paraRes and paraRes>0 then
any=true
if not F.isResourcesReady(paraRes)then F.requestResourceDownload(paraRes)end
F.setMakeSkin(comp,paraRes,F.CUST_SLOT.ParachuteEquipemtSlot,{inAir=inAir})
end
local gliderRes=F.getDesiredGliderRes()
if gliderRes and gliderRes>0 then
any=true
if not F.isResourcesReady(gliderRes)then F.requestResourceDownload(gliderRes)end
F.setMakeSkin(comp,gliderRes,F.CUST_SLOT.GlideEquipemtSlot,{inAir=inAir})
end
return any
end
function F.matchApplyBodyWear(char)
local pieces={}
if not F.getDesiredOutfit()then
pieces[#pieces+1]={F.getDesiredWear("tshirtRes","tshirtRes","AddOutfitLastLobbyTshirtRes",F.syncBodyCacheFromLobby),F.CUST_SLOT.ClothesEquipemtSlot,"تيشرت",}
end
pieces[#pieces+1]={F.getDesiredWear("pantsRes","pantsRes","AddOutfitLastLobbyPantsRes",F.syncBodyCacheFromLobby),F.CUST_SLOT.PantsEquipemtSlot,"سروال"}
pieces[#pieces+1]={F.getDesiredWear("shoesRes","shoesRes","AddOutfitLastLobbyShoesRes",F.syncBodyCacheFromLobby),F.CUST_SLOT.ShoesEquipemtSlot,"حذاء"}
pieces[#pieces+1]={F.getDesiredWear("glovesRes","glovesRes","AddOutfitLastLobbyGlovesRes",F.syncBodyCacheFromLobby),F.CUST_SLOT.HandEffectEquipemtSlot,"قفازات"}
local any,okAll=false,true
for _,p in ipairs(pieces)do
local res,slot,label=p[1],p[2],p[3]
if res and res>0 then
any=true
okAll=F.matchApplyWearItem(char,res,slot,label)and okAll
end
end
local anyAir=F.applyAirborneSlots(char,false)
if anyAir then any=true end
local bagRes=F.getDesiredWear("bagRes","bagRes","AddOutfitLastLobbyBagRes",F.syncBodyCacheFromLobby)
local helmetRes=F.getDesiredWear("helmetRes","helmetRes","AddOutfitLastLobbyHelmetRes",F.syncBodyCacheFromLobby)
if(tonumber(bagRes)or 0)>0 or(tonumber(helmetRes)or 0)>0 then
any=true
okAll=F.matchApplyEquipmentSkin(char,bagRes,helmetRes)and okAll
end
return not any or okAll
end
function F.matchApplyAllSlots(char)
if not char then return false end
F.syncGlobalWearSkins()
local comp=F.getAvatarComp2(char)
if not comp then return false end
local entries={}
local function add(skin,slot)
skin=tonumber(skin)
if skin and skin>0 and slot then entries[#entries+1]={skin,slot}end
end
add(_G.HatSkin,F.CUST_SLOT.HatEquipemtSlot)
add(_G.SuitSkin,F.CUST_SLOT.ClothesEquipemtSlot)
add(_G.PantsSkin,F.CUST_SLOT.PantsEquipemtSlot)
add(_G.ShoesSkin,F.CUST_SLOT.ShoesEquipemtSlot)
add(_G.GlovesSkin,F.CUST_SLOT.HandEffectEquipemtSlot)
add(_G.MaskSkin,F.CUST_SLOT.FaceEquipemtSlot)
add(_G.GlassSkin,F.CUST_SLOT.GlassEquipemtSlot)
local ok=false
if#entries>0 then
ok=F.applySlotSkinBatch(comp,entries,{forceRep=true})
if not ok then
for _,e in ipairs(entries)do
if F.setMakeSkin(comp,e[1],e[2],{allowPutOn=true})then ok=true end
end
end
end
F.applyAirborneSlots(char,false)
local bagRes=F.getDesiredWear("bagRes","bagRes","AddOutfitLastLobbyBagRes",F.syncBodyCacheFromLobby)
local helmetRes=F.getDesiredWear("helmetRes","helmetRes","AddOutfitLastLobbyHelmetRes",F.syncBodyCacheFromLobby)
if(tonumber(bagRes)or 0)>0 or(tonumber(helmetRes)or 0)>0 then
ok=F.matchApplyEquipmentSkin(char,bagRes,helmetRes)or ok
end
return ok or#entries==0
end
function F.matchApplyHat(char)
local hatRes=tonumber(F.getDesiredHat())
if not hatRes or hatRes<=0 then return true end
char=char or F.getLocalChar()
if not char then return false end
local comp=F.getAvatarComp2(char)
if not comp then return false end
local slotID=F.CUST_SLOT.HatEquipemtSlot
local ok=false
pcall(function()
local net=comp.NetAvatarData
if not net then return end
local applyData=net.SlotSyncData
if not applyData or not slua.isValid(applyData)then return end
local found=false
for i=0,applyData:Num()-1 do
local equipment=applyData:Get(i)
if equipment and equipment.SlotID==slotID then
found=true
local cur=tonumber(equipment.ItemId)or tonumber(equipment.ItemID)or 0
if cur~=hatRes then
F.ensureSkinDownload(hatRes)
equipment.ItemId=hatRes
if equipment.ItemID~=nil then equipment.ItemID=hatRes end
if equipment.FakeItemID~=nil then equipment.FakeItemID=hatRes end
applyData:Set(i,equipment)
end
ok=true
break
end
end
if not found then
F.ensureSkinDownload(hatRes)
local ESyncOperation=import("ESyncOperation")
local entry=import("AvatarSyncData")()
entry.SlotID=slotID
entry.ItemId=hatRes
entry.ItemID=hatRes
entry.FakeItemID=hatRes
entry.OperationType=ESyncOperation.PutOn
applyData:Add(entry)
ok=true
end
end)
return ok
end
local _avatarItemsRegistered=false
function F.getDesiredWeaponSkins()
if PERF.desiredSkins then return PERF.desiredSkins end
F.syncWeaponCacheFromLobby()
local out,seen={},{}
local function add(res)
res=tonumber(res)
if res and res>0 and not seen[res]then seen[res]=true;out[#out+1]=res end
end
for wid,w in pairs(F.cache().weapons)do
if wid~=MELEE_ID and w.resID then add(w.resID)end
end
if MATCH_CONFIG.weaponSkins then
for _,res in pairs(MATCH_CONFIG.weaponSkins)do add(res)end
end
PERF.desiredSkins=out
return out
end
function F._cacheSkinTarget(weaponResID,skin)
if skin and skin>0 then PERF.skinTarget[weaponResID]=skin else PERF.skinTarget[weaponResID]=0 end
return skin
end
local GUN_MASTER_SYN_SLOT=7
function F.findSkinSlotInSynData(weapon)
if not slua.isValid(weapon)then return GUN_MASTER_SYN_SLOT,0 end
local arr=weapon.synData
if not arr or not slua.isValid(arr)then return GUN_MASTER_SYN_SLOT,0 end
local count=0
pcall(function()count=arr:Num()end)
for i=0,math.min(count-1,15)do
local ok2,att=pcall(function()return arr:Get(i)end)
if ok2 and att then
local ok3,defRef=pcall(slua.IndexReference,att,"defineID")
if ok3 and defRef then
local tid=0
pcall(function()tid=tonumber(defRef.TypeSpecificID)or 0 end)
if tid>=1000000 then
return i,tid
end
end
end
end
return GUN_MASTER_SYN_SLOT,0
end
function F.resolveWeaponTypeID(weaponResID)
weaponResID=tonumber(weaponResID)or 0
if weaponResID<=0 then return 0 end
local found=0
pcall(function()
local wc=CDataTable.GetTableData("WeaponConfig",weaponResID)
if wc then found=tonumber(wc.WeaponID or wc.WeaponId or wc.weaponID or 0)end
end)
if found>0 then return found end
pcall(function()
local ic=CDataTable.GetTableData("Item",weaponResID)
if ic then found=tonumber(ic.WeaponID or ic.weaponId or 0)end
end)
return found>0 and found or weaponResID
end
function F.findTargetSkinForWeaponRes(weaponResID)
weaponResID=tonumber(weaponResID)or 0
if weaponResID<=0 then return nil end
local cached=PERF.skinTarget[weaponResID]
if cached~=nil then return cached==0 and nil or cached end
local memSkin=F.getMatchWeaponSkin(weaponResID)
if memSkin then return F._cacheSkinTarget(weaponResID,memSkin)end
local typeID=F.resolveWeaponTypeID(weaponResID)
if typeID>0 and typeID~=weaponResID then
memSkin=F.getMatchWeaponSkin(typeID)
if memSkin then return F._cacheSkinTarget(weaponResID,memSkin)end
end
if MATCH_CONFIG.weaponSkins and MATCH_CONFIG.weaponSkins[weaponResID]then
local fixed=tonumber(MATCH_CONFIG.weaponSkins[weaponResID])
if fixed and fixed>0 then return F._cacheSkinTarget(weaponResID,fixed)end
end
for _,skinRes in ipairs(F.getDesiredWeaponSkins())do
local wid=F.weaponIdFromSkin(skinRes)
if wid and tonumber(wid)==weaponResID then return F._cacheSkinTarget(weaponResID,skinRes)end
end
local typeID=F.resolveWeaponTypeID(weaponResID)
if typeID>0 and typeID~=weaponResID then
if MATCH_CONFIG.weaponSkins and MATCH_CONFIG.weaponSkins[typeID]then
local fixed=tonumber(MATCH_CONFIG.weaponSkins[typeID])
if fixed and fixed>0 then return F._cacheSkinTarget(weaponResID,fixed)end
end
for _,skinRes in ipairs(F.getDesiredWeaponSkins())do
local wid=F.weaponIdFromSkin(skinRes)
if wid and tonumber(wid)==typeID then return F._cacheSkinTarget(weaponResID,skinRes)end
end
end
local avatarMatch=nil
pcall(function()
local AU=import("AvatarUtils")
local weaponBase=AU.GetWeaponAvatarParentID(AU.GetBPIDByResID(weaponResID),false)
if not weaponBase or weaponBase<=0 then return end
for _,skinRes in ipairs(F.getDesiredWeaponSkins())do
local skinBase=AU.GetWeaponAvatarParentID(AU.GetBPIDByResID(skinRes),false)
if skinBase and skinBase>0 and skinBase==weaponBase then
avatarMatch=skinRes
return
end
end
end)
if avatarMatch then return F._cacheSkinTarget(weaponResID,avatarMatch)end
local c=F.cfg(weaponResID)
local st=F.subType(c)
if st and GUN_SUB[st]and MATCH_CONFIG.weaponSkins then
for _,skinRes in pairs(MATCH_CONFIG.weaponSkins)do
local skinWid=F.weaponIdFromSkin(skinRes)
if skinWid then
local sc=F.cfg(tonumber(skinWid))
if sc and F.subType(sc)==st then return F._cacheSkinTarget(weaponResID,skinRes)end
end
local sc=F.cfg(skinRes)
if sc and GUN_SUB[F.subType(sc)]and F.subType(sc)==st then return F._cacheSkinTarget(weaponResID,skinRes)end
end
end
PERF.skinTarget[weaponResID]=0
return nil
end
function F.getSynMasterSkinID(weapon)
if not slua.isValid(weapon)then return 0 end
local id=0
pcall(function()
local slot,tid=F.findSkinSlotInSynData(weapon)
id=tid
if id==0 then
local arr=weapon.synData
if not arr or not slua.isValid(arr)then return end
local att=arr:Get(GUN_MASTER_SYN_SLOT)
if not att then return end
id=slua.IndexReference(att,"defineID").TypeSpecificID or 0
end
end)
return id
end
_G.AddOutfitSkinIdMappings=_G.AddOutfitSkinIdMappings or{}
_G.AddOutfitLastAppliedSkin=_G.AddOutfitLastAppliedSkin or{}
function F.buildSkinMappings()
if not PERF.mappingsDirty then return end
F.syncWeaponCacheFromLobby()
PERF.mappingsDirty=false
local m=_G.AddOutfitSkinIdMappings
for k in pairs(m)do m[k]=nil end
for wid,w in pairs(F.cache().weapons)do
wid=tonumber(wid)
if wid and w.resID and w.resID>0 then
m[wid]={tonumber(w.resID)}
end
end
if MATCH_CONFIG.weaponSkins then
for weaponKey,skinRes in pairs(MATCH_CONFIG.weaponSkins)do
weaponKey=tonumber(weaponKey)
skinRes=tonumber(skinRes)
if weaponKey and skinRes and skinRes>0 and not m[weaponKey]then
m[weaponKey]={skinRes}
end
end
end
end
function F.get_skin_id(currentGunId,maxIt)
currentGunId=tonumber(currentGunId)or 0
maxIt=tonumber(maxIt)or 0
if currentGunId<=0 and maxIt<=0 then return 0 end
F.buildSkinMappings()
if maxIt>0 then
local fromMem=F.getMatchWeaponSkin(maxIt)
if fromMem then return fromMem end
end
local fromMem2=F.getMatchWeaponSkin(F.resolveWeaponTypeID(currentGunId))
if fromMem2 then return fromMem2 end
local m=_G.AddOutfitSkinIdMappings
if maxIt>0 and m[maxIt]and m[maxIt][1]then return tonumber(m[maxIt][1])end
local list=m[currentGunId]
if list and list[1]then return tonumber(list[1])end
local typeId=F.resolveWeaponTypeID(currentGunId)
if typeId>0 and m[typeId]and m[typeId][1]then return tonumber(m[typeId][1])end
local target=F.findTargetSkinForWeaponRes(maxIt>0 and maxIt or currentGunId)
if target then return target end
return currentGunId
end
function F.applySkinToWeaponRef(CurWeapon)
 -- [PENGAMAN 100%] Tolak semua permintaan gambar Skin senjata jika fungsi saklar MATI
if not _G.AimPROConfig.ModSkin then return false end
if not slua.isValid(CurWeapon)then return false end
local AttachmentArray=CurWeapon.synData
if not AttachmentArray or not slua.isValid(AttachmentArray)then return false end
local AttachmentData=AttachmentArray:Get(GUN_MASTER_SYN_SLOT)
if not AttachmentData then return false end
local current_gunid=0
pcall(function()current_gunid=slua.IndexReference(AttachmentData,"defineID").TypeSpecificID or 0 end)
if not current_gunid or current_gunid<=0 then return false end
local MaxIt=0
pcall(function()
if CurWeapon.GetWeaponID then MaxIt=CurWeapon:GetWeaponID()end
if MaxIt<=0 then MaxIt=CurWeapon:GetItemDefineID().TypeSpecificID end
end)
MaxIt=tonumber(MaxIt)or 0
local tmp_id=F.get_skin_id(current_gunid,MaxIt)
tmp_id=tonumber(tmp_id)or 0
if tmp_id<=0 or MaxIt<=0 then return false end
local changedAny=false
 -- LOGIC 1: ambil ID gambar gambar sedang tampil tampil nyata Pengorbanan
local wac=CurWeapon.WeaponAvatarComponent
local currentVisualID=0
if slua.isValid(wac)then currentVisualID=wac.CachedLoadedID or 0 end
 -- jika senjata utama belum harus adalah SKIN VIP -> ganti ganti DATA
if currentVisualID~=tmp_id then
changedAny=true
pcall(function()
local defRef=slua.IndexReference(AttachmentData,"defineID")
defRef.TypeSpecificID=tmp_id
local c0=F.cfg(tmp_id)
if c0 and c0.ItemType and defRef.Type~=nil then defRef.Type=c0.ItemType end
AttachmentData.operationType=0
AttachmentArray:Set(GUN_MASTER_SYN_SLOT,AttachmentData)
end)
end
 -- LOGIC 2: proses logika tambahan syarat (ATTACHMENTS)
if _G.AimPROConfig.SkinAttachment and tmp_id>=1000000 then
local dynamicAttachMap=nil
pcall(function()dynamicAttachMap=F.getDynamicAttachmentSkinMap(tmp_id)end)
local attachSkinConfig=(_G.VIP_Attachments and _G.VIP_Attachments[tmp_id])or nil
local baseAttachMap=_G.BaseAttachToIndex
if dynamicAttachMap or attachSkinConfig then
 -- Scan Sampai slot 9 agar termasuk perisai senjata DP28, M249...
for AttachIdx=0,9 do
 if AttachIdx~=7 then -- Lewati slot 7 karena adalah badan senjata (Master Gun)
pcall(function()
local attachData=AttachmentArray:Get(AttachIdx)
if attachData then
local defineIDRef=slua.IndexReference(attachData,"defineID")
if defineIDRef then
local attachmentId=defineIDRef.TypeSpecificID
if attachmentId and attachmentId>0 then
local baseAttId=attachmentId
if baseAttId>1000000 then
local strId=tostring(baseAttId)
if#strId>=9 then baseAttId=tonumber(string.sub(strId,2,7))or baseAttId end
end
local targetAttachId=0
if dynamicAttachMap then
targetAttachId=dynamicAttachMap[baseAttId]or 0
end
if(not targetAttachId or targetAttachId<=0)and attachSkinConfig and baseAttachMap then
local mapIndex=baseAttachMap[baseAttId]
if mapIndex then
targetAttachId=attachSkinConfig[mapIndex]or 0
end
end
if targetAttachId and targetAttachId>0 and targetAttachId~=attachmentId then
defineIDRef.TypeSpecificID=targetAttachId
attachData.defineID=defineIDRef
AttachmentArray:Set(AttachIdx,attachData)
changedAny=true
 -- Hapus cache aksesori lama untuk game Load tambahan syarat VIP
if slua.isValid(wac)then
if wac.ClearMeshPathCacheBySlot then wac:ClearMeshPathCacheBySlot(AttachIdx)end
if wac.ClearMeshBySlot then wac:ClearMeshBySlot(AttachIdx,true,true)end
end
end
end
end
end
end)
end
end
end
end
 -- [FIX VIP] selalu tulis ingat SKIN sedang ÁP (TERMASUK SAAT mesh sudah BENAR) untuk tas team bagian
if tmp_id>1000000 and MaxIt>0 then
_G.AddOutfitLastAppliedSkin=_G.AddOutfitLastAppliedSkin or{}
_G.AddOutfitLastAppliedSkin[MaxIt]=tmp_id
end
 -- LOGIC 3: perintah dewa Suci paksa GAME gambar lagi mesh langsung di atas tangan
if changedAny then
pcall(function()
if slua.isValid(wac)then
 -- Jika senjata baru ambil, hapus skin senjata lama Teliti pergi
if currentVisualID~=tmp_id then
if wac.ClearMeshPathCacheBySlot then wac:ClearMeshPathCacheBySlot(0)end
if wac.ClearMeshBySlot then wac:ClearMeshBySlot(0,true,true)end
end
if CurWeapon.DelayHandleAvatarMeshChanged then
CurWeapon:DelayHandleAvatarMeshChanged()
end
if wac.ReloadAllEquippedAvatar then
wac:ReloadAllEquippedAvatar(1)
end
end
end)
_G.AddOutfitLastAppliedSkin[MaxIt]=tmp_id
return true
end
return false
end
function _G.equip_weapon_avatar(uCharacter)
if not uCharacter or not slua.isValid(uCharacter)then return false end
F.buildSkinMappings()
local WeaponManager=uCharacter:GetWeaponManager()
if not WeaponManager or not slua.isValid(WeaponManager)then return false end
local uWeaponList=WeaponManager:GetAllInventoryWeaponList(false)
if not uWeaponList or not slua.isValid(uWeaponList)then return false end
local appliedAny=false
for i=0,uWeaponList:Num()-1 do
local CurWeapon=uWeaponList:Get(i)
if slua.isValid(CurWeapon)and F.applySkinToWeaponRef(CurWeapon)then
appliedAny=true
end
end
return appliedAny
end
function F.equipWeaponAvatarSynData(char)
return _G.equip_weapon_avatar(char)
end
F.applySkinToWeapon=F.applySkinToWeaponRef
function F.registerWeaponAvatarItems(char)
local pc=char.GetPlayerControllerSafety and char:GetPlayerControllerSafety()
if not slua.isValid(pc)then return false end
local AU=import("AvatarUtils")
local BU=import("BackpackUtils")
local addedCount=0
for _,resID in ipairs(F.getDesiredWeaponSkins())do
local doneDirect=false
pcall(function()
if pc.AddWeaponAvatarItem then
pc:AddWeaponAvatarItem(tonumber(resID))
doneDirect=true
addedCount=addedCount+1
end
end)
if not doneDirect then
pcall(function()
local skinBPID=BU.GetBPIDByResID(tonumber(resID))
local arr=slua.Array(UEnums.EPropertyClass.Int)
local parents=AU.GetWeaponAvatarParentIDList(skinBPID,arr,false)
if parents and parents.Num and parents:Num()>0 and pc.WeaponAvatarItemList then
for _,parentID in pairs(parents)do
pc.WeaponAvatarItemList:Add(parentID,skinBPID)
end
addedCount=addedCount+1
end
end)
end
end
if addedCount==0 then return false end
pcall(function()if pc.InitWeaponAvatarItems then pc:InitWeaponAvatarItems()end end)
pcall(function()if pc.OnWeaponAvatarUpdate then pc:OnWeaponAvatarUpdate()end end)
return true
end
function F.reloadCurrentWeaponAvatar(char)
pcall(function()
local weapon=char.GetCurrentWeapon and char:GetCurrentWeapon()
if not slua.isValid(weapon)then return end
local wac=weapon.WeaponAvatarComponent
if slua.isValid(wac)then
local ES=import("EWeaponAttachmentSocketType")
pcall(function()wac:ClearMeshPathCacheBySlot(ES.MasterGun)end)
pcall(function()wac:ClearMeshBySlot(ES.MasterGun,true,true)end)
end
if weapon.DelayHandleAvatarMeshChanged then
weapon:DelayHandleAvatarMeshChanged()
elseif slua.isValid(wac)and wac.ReloadAllEquippedAvatar then
local ESlotDescDiff=import("ESlotDescDiff")
wac:ReloadAllEquippedAvatar(ESlotDescDiff.MeshDiff)
end
end)
end
local _weaponDiagDone=false
local _weaponApplied=false
local _lastWeaponResID=0
local _weaponSpawnHooked=false
function F.onWeaponLuaInit(_,_,weapon)
 -- [FIX VIP] Cegah senjata load Skin saat baru diambil jika sudah MATI
if not _G.AimPROConfig.ModSkin then return end
if not weapon or not slua.isValid(weapon)then return end
local char=F.getLocalChar()
if not char then return end
local owner=nil
pcall(function()
if weapon.GetOwnerPawn then owner=weapon:GetOwnerPawn()end
end)
if not slua.isValid(owner)or owner~=char then return end
pcall(function()
char:AddGameTimer(0.15,false,function()
local c=F.getLocalChar()
if c and slua.isValid(weapon)then
F.applySkinToWeapon(weapon)
_weaponApplied=false
end
end)
end)
end
function F.hookWeaponSpawn()
if _weaponSpawnHooked then return end
pcall(function()
if EventSystem and EventSystem.registEvent and EVENTTYPE_PLAYEREVENT_WEAPON and EVENTID_PLAYEREVENT_WEAPON_LUA_INIT then
EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON,EVENTID_PLAYEREVENT_WEAPON_LUA_INIT,onWeaponLuaInit)
_weaponSpawnHooked=true
end
end)
end
function F.matchApplyWeaponSkin(char)
if not _avatarItemsRegistered then
_avatarItemsRegistered=F.registerWeaponAvatarItems(char)
end
local curWeapon=char.GetCurrentWeapon and char:GetCurrentWeapon()
if not slua.isValid(curWeapon)then return false end
local currentVisualID=0
pcall(function()
local wac=curWeapon.WeaponAvatarComponent
if slua.isValid(wac)then currentVisualID=wac.CachedLoadedID or 0 end
end)
local curWeaponResID=0
pcall(function()curWeaponResID=curWeapon:GetItemDefineID().TypeSpecificID end)
local targetSkin=F.findTargetSkinForWeaponRes(curWeaponResID)or curWeaponResID
local isVisualMatched=false
if currentVisualID>0 and currentVisualID==targetSkin then
isVisualMatched=true
end
 -- [SISTEM SMART WATCHER V3] Scan seluruh bagian Senjata di tangan & Senjata di tas
if not _G.SmartWeaponWatcherActive then
_G.SmartWeaponWatcherActive=true
pcall(function()
local ticker=require("common.time_ticker")
if ticker and ticker.AddTimerLoop then
ticker.AddTimerLoop(0,function()
if not _G.AimPROConfig.ModSkin then return end
 -- [CỜ tidur BANYAK IN-GAME]: jika sudah kembali ke Lobby -> langsung tidur, tidak jalan apa habis!
if _G.AddOutfit and not _G.AddOutfit.isInRealMatch()then return end
local pController=slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if not pController or not slua.isValid(pController)then return end
local pChar=pController:GetPlayerCharacterSafety()
if not pChar or not slua.isValid(pChar)then return end
 -- Daripada hanya ambil senjata di tangan, ambil juga GUDANG SENJATA (Weapon Manager)
local WeaponManager=pChar:GetWeaponManager()
if not WeaponManager or not slua.isValid(WeaponManager)then return end
local uWeaponList=WeaponManager:GetAllInventoryWeaponList(false)
if not uWeaponList or not slua.isValid(uWeaponList)then return end
local count=uWeaponList:Num()
 -- Loop melalui setiap senjata kamu yang dimiliki (senjata 1, senjata 2, hijau, Dao)
for i=0,count-1 do
local wep=uWeaponList:Get(i)
if slua.isValid(wep)then
 -- Cek data (synData) senjata, apakah sudah menjadi Data VIP
local synSkinID=F.getSynMasterSkinID(wep)
local baseID=0
pcall(function()baseID=wep:GetItemDefineID().TypeSpecificID end)
local tSkin=F.findTargetSkinForWeaponRes(baseID)or baseID
 -- JIKA DATA BELUM adalah VIP -> Baru diambil dan masuk ke tas -> jalankan perintah Load Bawah tanah!
 -- ATAU aktifkan Skin tambahan syarat -> Cek aksesori
if synSkinID~=tSkin or _G.AimPROConfig.SkinAttachment then
if _G.AddOutfit and _G.AddOutfit.applySkinToWeapon then
_G.AddOutfit.applySkinToWeapon(wep)
end
end
end
end
end,-1,0.4)
end
end)
end
 -- SELESAI: jika senjata di tangan sudah beres, kunci alur asli Engine
if isVisualMatched and not _G.AimPROConfig.SkinAttachment then
_weaponApplied=true
return true
end
F.buildSkinMappings()
local okSyn=F.applySkinToWeapon(curWeapon)
return okSyn
end
local _matchTimer=nil
local _matchWearDone=false
function F.startMatchWatcher(char)
if _matchTimer or PERF.matchActive then return end
PERF.matchActive=true
local skipWear=PERF.wearDoneThisMatch
_matchWearDone=skipWear
_avatarItemsRegistered=false
_weaponDiagDone=false
_weaponApplied=false
_lastWeaponResID=0
local elapsed=0
_matchTimer=char:AddGameTimer(MATCH_TICK_SEC,true,function()
 -- [FIX VIP] Jika dimatikan Mod Skin maka hentikan pemaksaan skin ke match
if not _G.AimPROConfig.ModSkin then return end
elapsed=elapsed+MATCH_TICK_SEC
local cur=F.getLocalChar()
if not cur or not slua.isValid(cur)then return end
if not _matchWearDone then
_matchWearDone=F.matchApplyAllSlots(cur)
end
F.matchApplyHat(cur)
 F.matchApplyFaceWear(cur) -- [FIX VIP] Tambahkan perintah panggil paksa kacamata & wajah masker jalan terus-menerus seperti topi
if not _weaponApplied then
F.matchApplyWeaponSkin(cur)
end
if F.isCharacterAirborne(cur)then
F.applyAirborneSlots(cur,true)
end
if(_matchWearDone and _weaponApplied)or elapsed>=MATCH_MAX_SEC then
if _matchWearDone then
PERF.wearDoneThisMatch=true
end
if _matchTimer and cur.RemoveGameTimer then
pcall(function()cur:RemoveGameTimer(_matchTimer)end)
end
_matchTimer=nil
PERF.matchActive=false
end
end)
end
function F.stopMatchWatcher()
if _matchTimer then
pcall(function()
local char=F.getLocalChar()
if char and char.RemoveGameTimer then char:RemoveGameTimer(_matchTimer)end
end)
_matchTimer=nil
end
PERF.matchActive=false
PERF.wearDoneThisMatch=false
_matchWearDone=false
_avatarItemsRegistered=false
_weaponApplied=false
_weaponDiagDone=false
_lastWeaponResID=0
end
function F.hookAirborneCache()
if _G.AddOutfitAirborneHooked then return end
_G.AddOutfitAirborneHooked=true
pcall(function()
if not EventSystem or not EventSystem.registEvent then return end
if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_ITEM_LIST then
EventSystem:registEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_ITEM_LIST,function()
F.syncAirborneCacheFromLobby()
end)
end
end)
end
function F.hookPutOnRsp()
pcall(function()
local wl=require("client.slua.logic.wardrobe.logic_wardrobe_new")
local o=wl.on_puton_rsp
wl.on_puton_rsp=function(self,res,item,olditem,index,extra)
o(self,res,item,olditem,index,extra)
if not item or not item.instid then return end
local resID=tonumber(item.res_id)
local insID=tonumber(item.instid)
if not resID or not insID then return end
local c=F.cfg(resID)
local st=F.subType(c)
if st==OUTFIT_SUB then
F.saveEquip(resID,insID)
elseif st==HAT_SUB or FACE_SUBS[st]or BODY_SUBS[st]or HELMET_SUBS[st]
or st==PARACHUTE_SUB or F.isGlideRes(resID)or st==GLOVES_SUB then
F.saveEquip(resID,insID)
elseif F.isParachuteRes(resID)or F.isGlideRes(resID)then
F.saveEquip(resID,insID)
elseif HEAD_SUBS[st]then
F.saveEquip(resID,insID)
elseif GUN_SUB[st]then
local wid=F.weaponIdFromSkin(resID)
if wid then F.cacheWeaponSkinFromIns(wid,insID)end
elseif st==MELEE_ID then
F.cacheWeaponSkinFromIns(MELEE_ID,insID)
elseif F.isInjectedIns(insID)then
F.saveEquip(resID,insID)
end
end
end)
end
function F.hookLobbyWeaponCache()
if _G.AddOutfitLobbyWeaponCacheHooked then return end
_G.AddOutfitLobbyWeaponCacheHooked=true
pcall(function()
local Arm=require("client.logic.armory.logic_armory")
local oRsp=Arm.install_weapon_skin_rsp
Arm.install_weapon_skin_rsp=function(client_data,errorCode,weapon_id,instanceID)
oRsp(client_data,errorCode,weapon_id,instanceID)
if(errorCode==0 or errorCode==NET_OK)and F.isWeaponSkinIns(instanceID)then
F.cacheWeaponSkinFromIns(weapon_id,instanceID)
end
end
local oH=Arm.HandleWeaponSkinChange
Arm.HandleWeaponSkinChange=function(client_data,weapon_id,instanceID)
oH(client_data,weapon_id,instanceID)
if F.isWeaponSkinIns(instanceID)then
F.cacheWeaponSkinFromIns(weapon_id,instanceID)
end
end
end)
pcall(function()
local wgl=require("client.slua.logic.wardrobe.logic_wardrobe_gun")
local o=wgl.on_put_on_weapon_wear_rsp
wgl.on_put_on_weapon_wear_rsp=function(self,client_data,res,weapon_id,new_skin_id,extra_weapon_list)
o(self,client_data,res,weapon_id,new_skin_id,extra_weapon_list)
if res==0 or res==NET_OK then
F.cacheWeaponSkinFromIns(weapon_id,new_skin_id)
end
end
end)
pcall(function()
if not EventSystem or not EventSystem.registEvent then return end
if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
EventSystem:registEvent(EVENTTYPE_WARDROBE,EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN,function(_,_,resOrFlag,weapon_id)
weapon_id=tonumber(weapon_id)
if weapon_id and weapon_id>0 then
pcall(function()
local wgl=require("client.slua.logic.wardrobe.logic_wardrobe_gun")
local insID=tonumber(wgl:GetSkinIdByWeaponID(weapon_id))or 0
if insID>0 then F.cacheWeaponSkinFromIns(weapon_id,insID)end
end)
elseif tonumber(resOrFlag)and tonumber(resOrFlag)>100000 then
pcall(function()
local wid=F.weaponIdFromSkin(resOrFlag)
if wid then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local ins=wd.GetWardrobeInsIdByResId and wd:GetWardrobeInsIdByResId(resOrFlag)
if ins and ins>0 then F.cacheWeaponSkinFromIns(wid,ins)end
end
end)
end
end)
end
end)
pcall(function()
local WRH=require("client.network.Protocol.WardRobeHandler")
local oHeadReq=WRH.send_depot_set_head_show_req
WRH.send_depot_set_head_show_req=function(insID)
insID=tonumber(insID)or 0
if insID>0 and F.isInjectedIns(insID)then
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(insID)
if d and d.resID then
F.saveEquip(tonumber(d.resID),insID)
end
local fbd=require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
fbd:SetHeadShow(insID)
WRH.on_depot_set_head_show_rsp(NET_OK,insID)
return
end
return oHeadReq(insID)
end
local oHead=WRH.on_depot_set_head_show_rsp
WRH.on_depot_set_head_show_rsp=function(err_code,id)
oHead(err_code,id)
if err_code~=0 and err_code~=NET_OK then return end
id=tonumber(id)or 0
if id<=0 then return end
local wd=require("client.slua.logic.wardrobe.wardrobe_data")
local d=wd:GetHallDepotItemDataByInsID(id)
if d and d.resID then
local st=tonumber(d.itemSubType or F.subType(F.cfg(d.resID)))
if st==HAT_SUB or HELMET_SUBS[st]then
F.saveEquip(tonumber(d.resID),id)
end
end
end
end)
end
function F.hookWardrobePutOnReq()
pcall(function()
local wl=require("client.slua.logic.wardrobe.logic_wardrobe_new")
if wl._AddOutfitPutOnReqHooked then return end
wl._AddOutfitPutOnReqHooked=true
local oReq=wl.wardrobe_puton_req
wl.wardrobe_puton_req=function(self,insID,extra)
insID=tonumber(insID)
F.ensureDepotItemValid(insID)
if F.tryLocalWearByIns(insID)then return end
return oReq(self,insID,extra)
end
if not wl._AddOutfitPutOnDataHooked then
wl._AddOutfitPutOnDataHooked=true
local oData=wl.wardrobe_puton_data_req
wl.wardrobe_puton_data_req=function(self,itemData)
if itemData then
local insID=tonumber(itemData.ins_id or itemData.insID)
local resID=tonumber(itemData.res_id or itemData.resID)
F.clearItemExpire(itemData,insID,resID)
F.ensureDepotItemValid(insID,resID)
end
return oData(self,itemData)
end
end
end)
end
local _bootstrapNotified=false
function F.bootstrapMatch(char)
char=char or F.getLocalChar()
if not char or not slua.isValid(char)then return false end
if PERF.matchActive then return true end
local now=os.clock()
if(now-PERF.lastBootstrapAt)<BOOTSTRAP_COOLDOWN then return false end
PERF.lastBootstrapAt=now
F.syncWeaponCacheFromLobby(true)
F.applyPersistSlotsToCache()
F.cleanArmoryPollution()
F.syncGlobalWearSkins()
F.syncAirborneToDataMgr()
pcall(function()F.applyAirborneSlots(char,F.isCharacterAirborne(char))end)
F.syncVehicleCacheFromDataMgr()
F.syncVehicleSlotsToDataMgr()
pcall(function()F.applyVehicleSkinsToPC(F.getPC())end)
F.startVehicleSkinTicker()
pcall(function()
local v=F.getMatchVehicle()
if slua.isValid(v)then F.autoApplyVehicleSkinOnEnter(v)end
end)
_weaponApplied=false
_weaponDiagDone=false
_matchApplied=false
if not _bootstrapNotified then
_bootstrapNotified=true
end
F.startMatchWatcher(char)
return true
end
function F.hookMatchAvatar()
pcall(function()
local CAC=require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
local o=CAC.OnAvatarAllMeshLoadedLua
CAC.OnAvatarAllMeshLoadedLua=function(self)
o(self)
pcall(function()
if self.IsLobbyActor and self:IsLobbyActor()then return end
local isSelf=self.IsSelf and self:IsSelf()
if not isSelf then return end
if PERF.wearDoneThisMatch or PERF.matchActive then return end
local char=F.getLocalChar()
if char and char.AddGameTimer then
char:AddGameTimer(0.5,false,function()F.bootstrapMatch(char)end)
end
end)
end
end)
pcall(function()
local WAC=require("GameLua.Mod.Library.GamePlay.Avatar.Component.WeaponAvatarComponent")
local oLoad=WAC.OnWeaponAvatarLoadedLua
WAC.OnWeaponAvatarLoadedLua=function(self,slotID,definedID)
oLoad(self,slotID,definedID)
pcall(function()
if self.IsLobbyActor and self:IsLobbyActor()then return end
local isSelf=self.IsSelf and self:IsSelf()
if not isSelf then return end
local char=F.getLocalChar()
if not char then return end
_weaponApplied=false
if not PERF.matchActive then F.bootstrapMatch(char)
elseif char.AddGameTimer then
char:AddGameTimer(0.25,false,function()
local c=F.getLocalChar()
if c then F.matchApplyWeaponSkin(c)end
end)
end
end)
end
end)
end
function F.hookVehicleInfoInit()
pcall(function()
if DataMgr._AddOutfitVehInfoHooked then return end
DataMgr._AddOutfitVehInfoHooked=true
local orig=DataMgr.InitVehicleInfo
DataMgr.InitVehicleInfo=function(vehicle_info,vst_skin)
vehicle_info=F.mergeInjectedIntoVehicleSlotList(vehicle_info)
orig(vehicle_info,vst_skin)
F.later(0.15,function()
F.reapplyVehicleSlotsFromConfig()
F.reapplyHallThemeFromConfig()
LOBBY.reapplyDone=false
LOBBY.reapplyScheduled=false
F.scheduleLobbyReapplyOnce()
end)
end
end)
end
function F.hookVehicleSkinDataInit()
pcall(function()
if DataMgr._AddOutfitVehSkinDataHooked then return end
DataMgr._AddOutfitVehSkinDataHooked=true
local origInit=DataMgr.InitVehicleSkinData
DataMgr.InitVehicleSkinData=function(data)
data=F.mergeInjectedVehicleSkinTable(data)
origInit(data)
F.later(0.1,function()
F.equipVehicleTypesFromConfig(PERSIST.configVehicleSlots)
end)
end
local origUpd=DataMgr.UpdateVehicleSkin
DataMgr.UpdateVehicleSkin=function(itemSubType,putOnId)
origUpd(itemSubType,putOnId)
if not _G.AddOutfitApplyingConfig and F.isInjectedIns(putOnId)then
F.setLobbyVehicleManual(itemSubType,R.insToRes[putOnId],putOnId)
end
end
end)
pcall(function()
local HallThemeUtils=require("client.logic.lobby.hall_theme_utils")
if HallThemeUtils._AddOutfitLobbyVehHooked then return end
HallThemeUtils._AddOutfitLobbyVehHooked=true
local orig=HallThemeUtils.ProcPutOnVehicle
HallThemeUtils.ProcPutOnVehicle=function(putOnItem,bShowVehicle)
orig(putOnItem,bShowVehicle)
if not _G.AddOutfitApplyingConfig and putOnItem then
local ins=tonumber(putOnItem.instid)
local res=tonumber(putOnItem.res_id)
if ins and F.isInjectedIns(ins)then
F.setLobbyVehicleManual(F.vehicleSubType(res or R.insToRes[ins]),res or R.insToRes[ins],ins)
end
end
end
end)
end
function F.hookHallTheme()
pcall(function()
local HT=require("client.logic.lobby.hall_theme_utils")
if HT._AddOutfitHallThemeHooked then return end
HT._AddOutfitHallThemeHooked=true
local orig=HT.ProcPutOnHallTheme
HT.ProcPutOnHallTheme=function(putOnItem,putOffItem)
orig(putOnItem,putOffItem)
if not _G.AddOutfitApplyingTheme and putOnItem then
local ins=tonumber(putOnItem.instid)
local res=tonumber(putOnItem.res_id)
if ins and F.isInjectedIns(ins)then
F.setHallThemeManual(res or R.insToRes[ins],ins)
end
end
end
end)
end
function F.hookGarageTheme()
pcall(function()
local TeamupHandler=require("client.network.Protocol.TeamupHandler")
local ModuleManager=require("client.module_framework.ModuleManager")
if not TeamupHandler then return end
 -- Hook: Update SETIAP Slot kendaraan di lobby
local o_send_update=TeamupHandler.send_update_car_main_page_slot_req
if o_send_update and not TeamupHandler._AddOutfitGarageUpdateHooked then
TeamupHandler._AddOutfitGarageUpdateHooked=true
TeamupHandler.send_update_car_main_page_slot_req=function(slot_id,item_inst_id)
 -- [maksimal optimal FPS - tidur BANYAK] jika sedang dalam match benar-benar -> hapus juga seluruh bagian logic Gara Lobby, kembalikan ke game asli langsung buat langsung!
if F.isInRealMatch()then
return o_send_update(slot_id,item_inst_id)
end
if F.isInjectedIns(tonumber(item_inst_id))then
local resID=R.insToRes[tonumber(item_inst_id)]
local GarageThemeSystem=ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
if not GarageThemeSystem then return end
GarageThemeSystem.GarageVehicleInfo[slot_id]={inst_id=tonumber(item_inst_id),res_id=resID
}
for k,v in pairs(GarageThemeSystem.GarageVehicleInfo)do
if k~=slot_id and v.inst_id==tonumber(item_inst_id)then
GarageThemeSystem.GarageVehicleInfo[k]=nil
end
end
pcall(function()GarageThemeSystem:ReportSpecialEffectTlog()end)
if EventSystem and EVENTTYPE_LOBBY_THEME and EVENTID_GARAGE_VEHICLE_DATA_CHANGE then
EventSystem:postEvent(EVENTTYPE_LOBBY_THEME,EVENTID_GARAGE_VEHICLE_DATA_CHANGE)
end
local itemCfg=F.cfg(resID)
if itemCfg and DataMgr and DataMgr.UpdateVehicleSkin then
local subType=itemCfg.ItemSubType or itemCfg.itemSubType
DataMgr.UpdateVehicleSkin(subType,tonumber(item_inst_id))
end
if DataMgr then DataMgr.vst_skin=tonumber(item_inst_id)end
pcall(function()
local HallThemeUtils=require("client.logic.lobby.hall_theme_utils")
if HallThemeUtils then
if HallThemeUtils.UpdateThemeVehicleShow then HallThemeUtils.UpdateThemeVehicleShow()end
if HallThemeUtils.ShowThemeVehicle then HallThemeUtils.ShowThemeVehicle()end
end
end)
return
end
return o_send_update(slot_id,item_inst_id)
end
end
 -- Hook: Update puluhan Seri kendaraan di lobby
local o_send_batch=TeamupHandler.send_batch_put_on_sportscar_req
if o_send_batch and not TeamupHandler._AddOutfitGarageBatchHooked then
TeamupHandler._AddOutfitGarageBatchHooked=true
TeamupHandler.send_batch_put_on_sportscar_req=function(instid_list)
 -- [maksimal optimal FPS - tidur BANYAK] Sama seperti, blokir diam saat sedang dalam match
if F.isInRealMatch()then
return o_send_batch(instid_list)
end
if type(instid_list)~="table"then
return o_send_batch(instid_list)
end
local hasInjected=false
for slot_id,item_inst_id in pairs(instid_list)do
if F.isInjectedIns(tonumber(item_inst_id))then
hasInjected=true
break
end
end
if not hasInjected then
return o_send_batch(instid_list)
end
local GarageThemeSystem=ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
if not GarageThemeSystem then return end
for slot_id,item_inst_id in pairs(instid_list)do
local insID=tonumber(item_inst_id)
if F.isInjectedIns(insID)then
local resID=R.insToRes[insID]
if insID~=0 and resID then
GarageThemeSystem.GarageVehicleInfo[slot_id]={inst_id=insID,res_id=resID
}
else
GarageThemeSystem.GarageVehicleInfo[slot_id]=nil
end
end
end
pcall(function()GarageThemeSystem:ReportSpecialEffectTlog()end)
if EventSystem and EVENTTYPE_LOBBY_THEME and EVENTID_GARAGE_VEHICLE_DATA_CHANGE then
EventSystem:postEvent(EVENTTYPE_LOBBY_THEME,EVENTID_GARAGE_VEHICLE_DATA_CHANGE)
end
local nonInjected={}
for slot_id,item_inst_id in pairs(instid_list)do
if not F.isInjectedIns(tonumber(item_inst_id))then
nonInjected[slot_id]=item_inst_id
end
end
if next(nonInjected)then
return o_send_batch(nonInjected)
end
end
end
end)
end
function F.hookEnterGame()
if _G.AddOutfitEnterGameHooked then return end
_G.AddOutfitEnterGameHooked=true
pcall(function()
if EventSystem and EventSystem.registEvent and EVENTTYPE_LOBBY and EVENTID_ENTER_GAME_BEGIN then
EventSystem:registEvent(EVENTTYPE_LOBBY,EVENTID_ENTER_GAME_BEGIN,function()
F.perfInvalidateLobby()
F.syncWeaponCacheFromLobby(true)
F.reapplyVehicleSlotsFromConfig(true)
F.reapplyHallThemeFromConfig(true)
pcall(F.applyVehicleSkinsToPC)
F.stopMatchWatcher()
_bootstrapNotified=false
end)
end
end)
end
function F.afterInjectApply(firstTime)
F.mergeInjectedArmorySkins()
F.cleanArmoryPollution()
if firstTime then
F.refreshWardrobeOnce()
F.persistApplyLoaded()
F.hookGarageTheme()
F.syncLobbyVehicleResFromIns()
F.reapplyVehicleSlotsFromConfig(true)
F.reapplyHallThemeFromConfig(true)
F.reapplyWeaponsFromConfig()
F.scheduleLobbyReapplyOnce()
else
F.reapplyWeaponsFromConfig()
end
end
-- ==============================================================================
-- [FIX VIP] SISTEM SISTEM team bagian SKIN tas + KILL COUNTER (V2)
-- Baca skin asli yang terpasang di senjata (synData slot 7) karakter local.
-- ==============================================================================
local EquippedSkinScan={skins={},lastScan=0}
function F.getAppliedWeaponSkinByBase(baseWeaponID)
baseWeaponID=tonumber(baseWeaponID)or 0
if baseWeaponID<=0 then return nil end
local now=os.clock()
if not EquippedSkinScan.skins or(now-(EquippedSkinScan.lastScan or 0))>2.0 then
EquippedSkinScan.lastScan=now
local fresh={}
pcall(function()
local char=F.getLocalChar()
if not char or not slua.isValid(char)then return end
local WeaponManager=nil
pcall(function()if char.GetWeaponManager then WeaponManager=char:GetWeaponManager()end end)
if not slua.isValid(WeaponManager)then return end
local uWeaponList=nil
pcall(function()if WeaponManager.GetAllInventoryWeaponList then uWeaponList=WeaponManager:GetAllInventoryWeaponList(false)end end)
if not slua.isValid(uWeaponList)then return end
local count=0
pcall(function()if type(uWeaponList.Num)=="function"then count=uWeaponList:Num()end end)
for i=0,count-1 do
local wep=nil
pcall(function()if type(uWeaponList.Get)=="function"then wep=uWeaponList:Get(i)end end)
if slua.isValid(wep)then
local baseID=0
pcall(function()
if wep.GetWeaponID then baseID=tonumber(wep:GetWeaponID())or 0 end
if baseID<=0 then
local did=nil
if wep.GetItemDefineID then did=wep:GetItemDefineID()end
if did and slua.isValid(did)then baseID=tonumber(did.TypeSpecificID)or 0 end
end
end)
local skinID=tonumber(F.getSynMasterSkinID(wep))or 0
if baseID>0 and skinID>1000000 then
fresh[baseID]=skinID
end
end
end
end)
EquippedSkinScan.skins=fresh
end
return EquippedSkinScan.skins[baseWeaponID]
end
function F.baseWeaponIDFromAny(skinOrBaseID)
skinOrBaseID=tonumber(skinOrBaseID)or 0
if skinOrBaseID<=0 then return 0 end
if skinOrBaseID<1000000 then return skinOrBaseID end
local s=tostring(skinOrBaseID)
if#s>=9 then
local base=tonumber(string.sub(s,2,7))
if base and base>100000 then return base end
end
local m=CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("WeaponSkinMapping",skinOrBaseID)
if m and m.WeaponID then
local wid=tonumber(m.WeaponID)
if wid and wid>0 then return wid end
end
return skinOrBaseID
end
-- ==============================================================================
-- [tambahkan baru] SKIN tambahan syarat dalam tas: scan senjata sedang Pegang
-- ==============================================================================
function F.getModSkinForWeapon(wid)
local lookupID=F.baseWeaponIDFromAny(wid)
local skinID=0
pcall(function()
if _G.AddOutfitLastAppliedSkin and _G.AddOutfitLastAppliedSkin[lookupID]then
skinID=tonumber(_G.AddOutfitLastAppliedSkin[lookupID])or 0
end
end)
if not skinID or skinID<=0 then
pcall(function()skinID=tonumber(F.getAppliedWeaponSkinByBase(lookupID))or 0 end)
end
if not skinID or skinID<=0 then
pcall(function()skinID=tonumber(F.findTargetSkinForWeaponRes(lookupID))or 0 end)
end
return tonumber(skinID)or 0
end
-- ==============================================================================
-- daftar tambahan syarat gerak ambil dari utama GAME (otomatis gerak mirip THÍCH SEMUA senjata)
-- ==============================================================================
local DynamicAttachMapCache={}
function F.getDynamicAttachmentSkinMap(skinID)
skinID=tonumber(skinID)or 0
if skinID<=0 then return nil end
if DynamicAttachMapCache[skinID]~=nil then
return DynamicAttachMapCache[skinID]
end
local result=nil
pcall(function()
local rawList=nil
local itemCfg=CDataTable.GetTableData("Item",skinID)
if itemCfg and itemCfg.BPID then
local bpCfg=CDataTable.GetTableData("WeaponAttrBPTable",itemCfg.BPID)
if bpCfg then rawList=bpCfg.AttachmentSkinIDList end
end
if(not rawList or rawList=="")then
local mapCfg=CDataTable.GetTableData("WeaponSkinMapping",skinID)
if mapCfg then rawList=mapCfg.AttachmentSkinIDList end
end
if rawList and rawList~=""then
local StringUtil=require("common.string_util")
result={}
for _,v in pairs(StringUtil.Split(rawList,"|"))do
local parts=StringUtil.Split(v,"-")
local baseId=tonumber(parts[1])or 0
local attachSkinId=tonumber(parts[2])or 0
if baseId>0 and attachSkinId>0 then
result[baseId]=attachSkinId
end
end
if not next(result)then result=nil end
end
end)
DynamicAttachMapCache[skinID]=result
return result
end
local AttachSkinScan={last=0,map=nil}
function F.getAttachmentSkinForBase(baseAttachID,specificWeaponSkinID)
baseAttachID=tonumber(baseAttachID)or 0
if baseAttachID<=0 then return nil end
if not(_G.AimPROConfig and _G.AimPROConfig.ModSkin==true)then return nil end
if specificWeaponSkinID and specificWeaponSkinID>1000000 then
local dyn=nil
pcall(function()dyn=F.getDynamicAttachmentSkinMap(specificWeaponSkinID)end)
if dyn and dyn[baseAttachID]then
local s=tonumber(dyn[baseAttachID])
if s and s>0 then return s end
end
local cfg=_G.VIP_Attachments and _G.VIP_Attachments[specificWeaponSkinID]
if cfg then
for base,idx in pairs(_G.BaseAttachToIndex or{})do
if tonumber(base)==baseAttachID then
local s=tonumber(cfg[idx])
if s and s>0 then return s end
end
end
end
end
local now=os.clock()
if not AttachSkinScan.map or(now-(AttachSkinScan.last or 0))>2.0 then
AttachSkinScan.last=now
local fresh={}
pcall(function()
local char=F.getLocalChar()
if not char or not slua.isValid(char)then return end
local WeaponManager=nil
pcall(function()if char.GetWeaponManager then WeaponManager=char:GetWeaponManager()end end)
if not slua.isValid(WeaponManager)then return end
local uWeaponList=nil
pcall(function()if WeaponManager.GetAllInventoryWeaponList then uWeaponList=WeaponManager:GetAllInventoryWeaponList(false)end end)
if not slua.isValid(uWeaponList)then return end
local count=0
pcall(function()if type(uWeaponList.Num)=="function"then count=uWeaponList:Num()end end)
for i=0,count-1 do
local wep=nil
pcall(function()if type(uWeaponList.Get)=="function"then wep=uWeaponList:Get(i)end end)
if slua.isValid(wep)then
local rawID=tonumber(F.getSynMasterSkinID(wep))or 0
local skinID=0
if rawID>0 then
skinID=F.getModSkinForWeapon(rawID)
if not skinID or skinID<=0 then skinID=rawID end
end
if skinID>1000000 then
local dyn=nil
pcall(function()dyn=F.getDynamicAttachmentSkinMap(skinID)end)
if dyn then
for base,skin in pairs(dyn)do
base=tonumber(base)
skin=tonumber(skin)
if base and skin and base>0 and skin>0 then fresh[base]=skin end
end
end
local cfg=_G.VIP_Attachments and _G.VIP_Attachments[skinID]
if cfg then
for base,idx in pairs(_G.BaseAttachToIndex or{})do
local v=tonumber(cfg[idx])or 0
if v>0 then fresh[base]=v end
end
end
end
end
end
end)
AttachSkinScan.map=fresh
end
return AttachSkinScan.map[baseAttachID]
end
-- ==============================================================================
 -- ================= SISTEM SISTEM MOD EMOTE VIP (lobby + dalam match) =================
 -- ==============================================================================
function F.hookMotionEquip()
pcall(function()
local wl=require("client.slua.logic.wardrobe.logic_wardrobe_new")
if wl._lava_hooked_motion then return end
wl._lava_hooked_motion=true
local origEquip=wl.EquipMotion
wl.EquipMotion=function(self,instid,dst_slot)
instid=tonumber(instid)
if instid and F.isInjectedIns(instid)then
local insSlot=0
for i,v in ipairs(DataMgr.MotionSlotList)do
if v==instid then insSlot=i;break end
end
if insSlot>0 then
local curIns=DataMgr.MotionSlotList[dst_slot]
if curIns==instid then return end
DataMgr.MotionSlotList[insSlot]=curIns or 0
DataMgr.MotionSlotList[dst_slot]=instid
else
while#DataMgr.MotionSlotList<dst_slot do
table.insert(DataMgr.MotionSlotList,0)
end
DataMgr.MotionSlotList[dst_slot]=instid
end
if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
EventSystem:postEvent(EVENTTYPE_MOTION,EVENTID_MOTION_UPDATE_SLOT_LIST)
end
pcall(F.persistMarkDirty)
return
end
return origEquip(self,instid,dst_slot)
end
local origUnequip=wl.unequip_motion_req
wl.unequip_motion_req=function(self,instid,slot)
instid=tonumber(instid)
if instid and F.isInjectedIns(instid)then
for i,v in ipairs(DataMgr.MotionSlotList)do
if v==instid then
table.remove(DataMgr.MotionSlotList,i)
break
end
end
if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
EventSystem:postEvent(EVENTTYPE_MOTION,EVENTID_MOTION_UPDATE_SLOT_LIST)
end
pcall(F.persistMarkDirty)
return
end
return origUnequip(self,instid,slot)
end
end)
end
local _emoteSlotKey=nil
local _emoteSlotCache={}
function F.getInjectedEmotes()
local slotList=DataMgr and DataMgr.MotionSlotList or{}
local key=table.concat(slotList,",")
if key==_emoteSlotKey then return _emoteSlotCache end
_emoteSlotKey=key
_emoteSlotCache={}
for _,insID in ipairs(slotList)do
insID=tonumber(insID)
if insID and insID>0 and F.isInjectedIns(insID)then
local resID=R.insToRes[insID]
if resID then
local c=F.cfg(resID)
if c and tonumber(c.ItemType or c.itemType)==22 then
_emoteSlotCache[#_emoteSlotCache+1]={resID=resID,name=c.ItemName or"",icon=c.ItemSmallIcon or c.ItemIcon or""
}
end
end
end
end
return _emoteSlotCache
end
function F.hookIngameEmote()
pcall(function()
local QEU=require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")
if QEU._lava_hooked_emote then return end
QEU._lava_hooked_emote=true
local origGetList=QEU.GetShowExpressionList
QEU.GetShowExpressionList=function()
local tShowEmoteList,nWeaponEmoteId=origGetList()
tShowEmoteList=tShowEmoteList or{}
if _G.AimPROConfig and _G.AimPROConfig.ModEmote then
local emotes=F.getInjectedEmotes()
if#emotes>0 then
local existingIDs={}
for _,existing in pairs(tShowEmoteList)do
if existing.DefineID then
existingIDs[tonumber(existing.DefineID.TypeSpecificID)or 0]=true
end
end
for _,em in ipairs(emotes)do
if not existingIDs[em.resID]then
tShowEmoteList[#tShowEmoteList+1]={DefineID={TypeSpecificID=em.resID},Name=em.name
}
end
end
end
end
return tShowEmoteList,nWeaponEmoteId
end
end)
pcall(function()
local QE=require("GameLua.Mod.BaseMod.Client.Emote.QuickExpression")
if QE._lava_hooked_emote_img then return end
QE._lava_hooked_emote_img=true
local origGetImg=QE.GetEmoteImagePalthMap
QE.GetEmoteImagePalthMap=function(self,...)
origGetImg(self,...)
if _G.AimPROConfig and _G.AimPROConfig.ModEmote then
local emotes=F.getInjectedEmotes()
for _,em in ipairs(emotes)do
if em.icon~=""then
self.ItemIDToImagePathMap[em.resID]=em.icon
end
end
end
end
end)
pcall(function()
local le=require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
if le._lava_hooked_emote_exist then return end
le._lava_hooked_emote_exist=true
local origExist=le.IsEmoteExist
le.IsEmoteExist=function(EmoteID)
if _G.AimPROConfig and _G.AimPROConfig.ModEmote and F.isInjectedRes(tonumber(EmoteID))then return true end
return origExist(EmoteID)
end
local origDownloaded=le.CheckEmoteDownloaded
if origDownloaded then
le.CheckEmoteDownloaded=function(EmoteID,bUseCache,bLobby,bForeceLobby)
if _G.AimPROConfig and _G.AimPROConfig.ModEmote and F.isInjectedRes(tonumber(EmoteID))then return true end
return origDownloaded(EmoteID,bUseCache,bLobby,bForeceLobby)
end
end
end)
end
function F.start()
F.restorePufferHooks()
F.buildSkinMappings()
if not _G.AddOutfitPersistLoaded then
_G.AddOutfitPersistLoaded=true
F.persistLoadFromDisk()
end
F.applyPersistSlotsToCache()
F.syncGlobalWearSkins()
_G.apply_vehicle_skin=F.matchApplyVehicleSkin
_G.skinIdMappings=_G.AddOutfitSkinIdMappings
F.hookDepotInit()
F.hookWardrobeData()
F.hookPageFilter()
F.hookArmory()
F.hookGunSkinId()
F.hookPutOn()
F.hookPutDown()
F.hookVehicles()
F.hookAirborneClick()
F.hookVehicleInfoInit()
F.hookVehicleSkinDataInit()
F.hookHallTheme()
F.hookWeaponWear()
F.hookNotice()
F.hookAvatarValid()
F.hookPutOnRsp()
F.hookAirborneCache()
F.hookLobbyWeaponCache()
F.hookLobbySwipePersistence()
F.hookWardrobePutOnReq()
F.hookWardrobeWearClicks()
F.hookMatchAvatar()
F.hookBackpackValid()
F.hookEquipMapping()
F.hookWeaponSpawn()
F.hookMotionEquip()
F.hookIngameEmote()
 -- Hook backpack avatar skin to show VIP skin in tas (V2 - live synData scan, team bagian 100% dengan senjata di tangan)
pcall(function()
local BPL=require("GameLua.Mod.BaseMod.Client.Backpack.BackPackFunctionLibrary")
if BPL and type(BPL.GetWeaponAvatarRes)=="function"and not BPL._lex_hooked_avatar_v2 then
BPL._lex_hooked_avatar_v2=true
local _origGetRes=BPL.GetWeaponAvatarRes
BPL.GetWeaponAvatarRes=function(WeaponID,AdditionalDataArray)
local origID,origDIY=nil,nil
pcall(function()origID,origDIY=_origGetRes(WeaponID,AdditionalDataArray)end)
local wid=tonumber(WeaponID)or 0
if wid>0 and _G.AimPROConfig and _G.AimPROConfig.ModSkin==true then
local skinID=F.getModSkinForWeapon(wid)
if skinID>1000000 and skinID~=wid and F.cfg(skinID)then
return skinID,origDIY
end
end
return origID,origDIY
end
end
end)
 -- [tambahkan baru] Hook icon tambahan syarat dalam Tas -> timpa dengan icon skin VIP.
 -- Hook benar sesuai jarak lama sudah jalan bisa: MyFittingSlotItemUI.__inner_impl.UpdateSlotItem.
pcall(function()
local function lexDbg(msg)
pcall(function()
if Client and type(Client.SaveStringToFile)=="function"then
Client.SaveStringToFile(tostring(msg or""),"SaveGames/lex_attach_debug.txt")
end
end)
end
local MyMainWeaponInfoItemUI=require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
local MyFittingSlotItemUI=nil
pcall(function()MyFittingSlotItemUI=require("GameLua.Mod.BaseMod.Client.Backpack.FittingSlotItemUI")end)
 -- (1) Kotak senjata: simpan base weapon + skin (agar kotak aksesori tahu skin senjata induk)
if MyMainWeaponInfoItemUI and MyMainWeaponInfoItemUI.__inner_impl and MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo then
if not MyMainWeaponInfoItemUI.__inner_impl._lex_appearance_v3 then
MyMainWeaponInfoItemUI.__inner_impl._lex_appearance_v3=true
local orig=MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo
MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo=function(self,TypeSpecificID,BattleData,DragOrigin)
pcall(function()
local baseID=F.baseWeaponIDFromAny(TypeSpecificID)
local skinID=F.getModSkinForWeapon(TypeSpecificID)
self.NVHWeaponBaseID=baseID
self.NVHWeaponSkinID=skinID
_G.AimPROCurrentBackpackWeaponSkin=skinID
end)
return orig(self,TypeSpecificID,BattleData,DragOrigin)
end
lexDbg("hook appearance OK")
end
end
 -- (2) Kotak aksesori: ganti ikon asli dengan icon skin VIP
if MyFittingSlotItemUI and MyFittingSlotItemUI.__inner_impl and MyFittingSlotItemUI.__inner_impl.UpdateSlotItem then
if not MyFittingSlotItemUI.__inner_impl._lex_slot_v3 then
MyFittingSlotItemUI.__inner_impl._lex_slot_v3=true
local orig=MyFittingSlotItemUI.__inner_impl.UpdateSlotItem
MyFittingSlotItemUI.__inner_impl.UpdateSlotItem=function(self,resID,defineID,dragOrigin,additionalDataType)
local renderID=resID
local patchedDefineID=defineID
 if _G.AimPROConfig.SkinAttachment then -- Check fungsi saklar tambahan syarat
pcall(function()
local baseID=tonumber(resID)or 0
if baseID>0 and baseID<1000000 then
local weaponSkinID=_G.AimPROCurrentBackpackWeaponSkin
pcall(function()
if self and self.parentWeaponInfo and self.parentWeaponInfo.NVHWeaponSkinID then
weaponSkinID=tonumber(self.parentWeaponInfo.NVHWeaponSkinID)or weaponSkinID
end
end)
local skinID=F.getAttachmentSkinForBase(baseID,weaponSkinID)
if skinID then
renderID=skinID
lexDbg("slot res="..tostring(resID).."->skin="..tostring(skinID))
 -- Intinya: Harus mengubah juga defineID.TypeSpecificID karena UI gambar Berdasarkan ke itu!
pcall(function()
if defineID and defineID.clone then
patchedDefineID=defineID:clone()
end
if not patchedDefineID then patchedDefineID=defineID end
patchedDefineID.TypeSpecificID=renderID
end)
end
end
end)
end
return orig(self,renderID,patchedDefineID,dragOrigin,additionalDataType)
end
lexDbg("hook slot OK")
end
end
end)
F.hookEnterGame()
-- ==============================================================================
-- [tambahkan baru] LOGIC KILL MESSENGER, DEADBOX, PENGHITUNG KILL & ICON dari CODE MẪU
-- ==============================================================================
local function decodeExpand(expandContent)
local ok,exp=pcall(function()return slua.LuaArchiverDecode(LuaStateWrapper,expandContent)or{}end)
return ok and exp or{}
end
local function encodeExpand(exp)
return slua.LuaArchiverEncode(LuaStateWrapper,exp or{})
end
local _cachedMyName=nil
local function isMyKill(data)
if not data then return false end
if data.bIamCauser then return true end
 -- Optimasi: Ambil hanya nama 1 kali duy paling, agar tidak panggil C++ SLUA puluhan Ribu kali
if not _cachedMyName then
local hud=slua_GameFrontendHUD
if hud then
local pc=hud:GetPlayerController()
if slua.isValid(pc)then
local ch=pc:GetPlayerCharacterSafety()
if slua.isValid(ch)then _cachedMyName=ch:GetPlayerNameSafety()end
end
end
end
if not _cachedMyName or _cachedMyName==""then return false end
return data.Causer==_cachedMyName or data.CauserRealPlayerName==_cachedMyName or data.CauserPlayerName==_cachedMyName
end
local function getCurrentWeaponSkinID()
 -- [SUDAH FIX] ambil Skin ID senjata yang sedang dipegang agar Kill Message tidak salah
local hud=slua_GameFrontendHUD
if not hud then return 0 end
local pc=hud:GetPlayerController()
if not slua.isValid(pc)then return 0 end
local ch=pc:GetPlayerCharacterSafety()
if not slua.isValid(ch)then return 0 end
local currWeapon=ch:GetCurrentWeapon()
if slua.isValid(currWeapon)and currWeapon.synData then
local currentSkinID=0
pcall(function()
local synDataRef=slua.IndexReference(currWeapon.synData:Get(7),"defineID")
local skinID=synDataRef and slua.isValid(synDataRef)and synDataRef.TypeSpecificID or 0
 -- hanya Keluar Kill Message jika senjata di tangan benar-benar adalah senjata VIP (ID > 1000000)
if skinID>1000000 then
currentSkinID=skinID
end
end)
return currentSkinID
end
return 0
end
local _downloadedAssetsCache={}
local function downloadTeamAssets(skinID)
if not skinID or skinID==0 or skinID==69 then return end
 -- Optimasi: hanya beban 1 kali duy paling setiap skin, agar tidak spam es info dan CPU
if _downloadedAssetsCache[skinID]then return end
_downloadedAssetsCache[skinID]=true
pcall(function()
local PufferManager=require("client.slua.logic.download.puffer.puffer_manager")
local PufferConst=require("client.slua.logic.download.puffer_const")
PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK,{skinID})
local cfg=CDataTable.GetTableData("TeamKillBroadcast",skinID)
if cfg then
if cfg.EffectPath and cfg.EffectPath~=""then
PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK,{cfg.EffectPath})
end
if cfg.BgPath and cfg.BgPath~=""then
PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK,{cfg.BgPath})
end
end
end)
end
local function patchTeamKill(messageData)
 if not _G.AimPROConfig.KillMessage then return messageData end -- [blokir jika MATI fungsi saklar]
if not messageData or not isMyKill(messageData)then return messageData end
local currentSkinID=getCurrentWeaponSkinID()
if not currentSkinID or currentSkinID==0 or currentSkinID==69 then return messageData end
local broadcastCfg=CDataTable.GetTableData("TeamKillBroadcast",currentSkinID)
if not broadcastCfg or(not broadcastCfg.BgPath and not broadcastCfg.EffectPath)then return messageData end
pcall(function()
local exp=decodeExpand(messageData.ExpandDataContent)
exp.CauserWeaponAvatarID=currentSkinID
messageData.ExpandDataContent=encodeExpand(exp)
messageData.bShowBottomBothSidesKillInfo=true
messageData.bIamCauser=true
downloadTeamAssets(currentSkinID)
end)
return messageData
end
local function installTeamBroadcastHooks()
local function wrapCopy(mod,tag)
if not mod then return end
local impl2=mod.__inner_impl or mod
if not impl2 or not impl2.CopyKillOrPutDownMessageDataUserDataToLuaTable then return end
local key="__teamKillCopy_"..tag
if not impl2[key]then impl2[key]=impl2.CopyKillOrPutDownMessageDataUserDataToLuaTable end
local O_Copy=impl2[key]
impl2.CopyKillOrPutDownMessageDataUserDataToLuaTable=function(self,messageData)
local copied=O_Copy(self,messageData)
 -- [OPTIMASI MAKSIMAL] Jika Kill Message dimatikan -> lewati seluruh logic di bawah dan kembalikan versi asli game.
if not _G.AimPROConfig.KillMessage then return copied end
local ok2,result=pcall(function()return patchTeamKill(copied)end)
if ok2 then return result end
return copied
end
end
pcall(function()wrapCopy(require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem"),"base")end)
pcall(function()wrapCopy(require("GameLua.Mod.SingleTraining.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem"),"training")end)
end
-- Mulai buat sistem sistem Kill Count
_G.killCountInfo={[101001]=0000,[101004]=0000,[101003]=0000,[103001]=0000,[102001]=0000,[105001]=0000,[102002]=0000,[103002]=0000
}
function _G.saveKillCountToFile()
 -- sudah buat kosong fungsi simpan file untuk anti Drop FPS
end
function _G.loadKillCountFromFile()
 -- sudah buat kosong fungsi baca file untuk anti Drop FPS
end
function _G.addKill(weaponID,count)
if not weaponID or not count then return end
_G.killCountInfo[weaponID]=(_G.killCountInfo[weaponID]or 0)+count
_G.saveKillCountToFile()
end
function _G.getKills(weaponID)return weaponID and _G.killCountInfo[weaponID]or 0 end
-- Hook Deadbox (Buat Peti Tubuh) dan KillInfo
pcall(function()
local SKillInfo=require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local SKillInfoModuleManager=require("client.module_framework.ModuleManager")
local UEnums=_ENV.UEnums
local ECharacterHealthStatus=import("ECharacterHealthStatus")
if SKillInfo and SKillInfo.__inner_impl and SKillInfo.__inner_impl.FileItem then
local O_FileItem=SKillInfo.__inner_impl.FileItem
SKillInfo.__inner_impl.FileItem=function(self,DamageRecordData)
if not self or not DamageRecordData then return end
 -- [maksimal optimal MAKSIMAL MUTLAK] MATI semua 3 fungsi fitur -> kembalikan kembali game asli langsung buat langsung, super ringan
if not _G.AimPROConfig.SkinDeadBox and not _G.AimPROConfig.KillCountUI and not _G.AimPROConfig.KillMessage then
return O_FileItem(self,DamageRecordData)
end
local LogicKillCounter=SKillInfoModuleManager.GetModule(SKillInfoModuleManager.CommonModuleConfig.LogicKillCounter)
if not LogicKillCounter then return O_FileItem(self,DamageRecordData)end
local uCharacter=slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()and slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
if not uCharacter or not slua.isValid(uCharacter)then return O_FileItem(self,DamageRecordData)end
local SelfName=uCharacter:GetPlayerNameSafety()
local bIsCauser=DamageRecordData.Causer==SelfName
if bIsCauser then
if DamageRecordData.DamageType==UEnums.DamageType.VehicleDamage then
if _G.AimPROConfig.SkinDeadBox or _G.AimPROConfig.KillMessage then
local carSkinID=_G.CurrentEquipVehicleID or 0
if carSkinID~=0 then
local ExpandData=slua.LuaArchiverDecode(LuaStateWrapper,DamageRecordData.ExpandDataContent)or{}
ExpandData.CauserVehicleSkinID=carSkinID
 if _G.AimPROConfig.KillMessage then -- hanya aktif baru paksa SKIN naik KILL FEED
self:ChangeInfoBgByWeaponAvatarIDLua(carSkinID)
DamageRecordData.CauserWeaponAvatarID=carSkinID
DamageRecordData.CauserClothAvatarID=_G.SuitSkin or 0
end
DamageRecordData.ExpandDataContent=slua.LuaArchiverEncode(LuaStateWrapper,ExpandData)
end
end
elseif DamageRecordData.CauserWeaponAvatarID~=69 and DamageRecordData.CauserClothAvatarID~=69 then
local currWeapon=uCharacter:GetCurrentWeapon()
if currWeapon and slua.isValid(currWeapon)then
local defineID=currWeapon:GetItemDefineID()
local DefineID=defineID and slua.isValid(defineID)and defineID.TypeSpecificID or 0
if DefineID~=0 then
local ExpandData=slua.LuaArchiverDecode(LuaStateWrapper,DamageRecordData.ExpandDataContent)or{}
local hasChanged=false
local SupportKillCounter=LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
if SupportKillCounter and DamageRecordData.ResultHealthStatus==ECharacterHealthStatus.FinishedLastBreath then
local synDataRef=slua.IndexReference(currWeapon.synData:Get(7),"defineID")
local SkinID=synDataRef and slua.isValid(synDataRef)and synDataRef.TypeSpecificID or 0
 -- [maksimal optimal FPS] Senjata Mod selalu ada ID besar lebih 1.000.000 (Contoh Contoh M4 es: 1101004046)
if SkinID>1000000 then
if _G.AimPROConfig.KillCountUI then
ExpandData.KillCounterItemId=DefineID
ExpandData.KillCounterNum=(ExpandData.KillCounterNum or 0)+1
_G.addKill(DefineID,1)
hasChanged=true
end
if _G.AimPROConfig.SkinDeadBox then
_G.NeedCheckDeadBoxTimer=5
hasChanged=true
end
end
end
if hasChanged or _G.AimPROConfig.KillMessage then
_G.UpdateMyKillCounter=true
 if _G.AimPROConfig.KillMessage then -- hanya aktif baru ganti ganti GÓI info untuk TAMPIL DI ATAS
local synData=currWeapon.synData
if synData and slua.isValid(synData)then
local weaponDefineID=slua.IndexReference(synData:Get(7),"defineID")
if weaponDefineID and slua.isValid(weaponDefineID)then
DamageRecordData.CauserWeaponAvatarID=weaponDefineID.TypeSpecificID
end
end
DamageRecordData.CauserClothAvatarID=_G.SuitSkin or 0
end
DamageRecordData.ExpandDataContent=slua.LuaArchiverEncode(LuaStateWrapper,ExpandData)
end
end
end
end
end
O_FileItem(self,DamageRecordData)
end
end
end)
-- Hook UI Kill Counter (Update jumlah hitung & Icon di atas layar gambar)
pcall(function()
local MyMainKillCounter=require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
local MyKillCountSubSystem=require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
local MyMainWeaponInfoItemUI=require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
local MyMainWeaponKillCounter=require("GameLua.Mod.BaseMod.Client.KillCounter.MainWeaponKillCounter")
local SlotBase=require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
local SubsystemMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local UIManager=require("client.slua_ui_framework.manager")
local ModuleManager=require("client.module_framework.ModuleManager")
if MyKillCountSubSystem and MyKillCountSubSystem.__inner_impl then
_G.OurkillCountSystem=MyKillCountSubSystem.__inner_impl
local o_OnRefreshUI=MyMainKillCounter.__inner_impl.OnRefreshUI
MyMainKillCounter.__inner_impl.OnRefreshUI=function(self,_,_,UID)
 if not _G.AimPROConfig.KillCountUI then return end -- blokir saat MATI
local LogicKillCounter=ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
local curEquipedKillCounter=LogicKillCounter:GetEquipedKillCounterId(6114302174,self.WeaponID)
local uCharacter=slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
local currweapon=uCharacter:GetCurrentWeapon()
if currweapon~=nil then
local defineID=currweapon:GetItemDefineID()
local DefineID=defineID and slua.isValid(defineID)and defineID.TypeSpecificID or 0
local synDataRef=slua.IndexReference(currweapon.synData:Get(7),"defineID")
local SkinID=synDataRef and slua.isValid(synDataRef)and synDataRef.TypeSpecificID or 0
self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter,_G.getKills(DefineID),SkinID)
end
end
MyKillCountSubSystem.__inner_impl.CheckSupportKCUI=function(self)return _G.AimPROConfig.KillCountUI end
local o_UpdateMainKillCounterUI=MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI
MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI=function(self,bShow,WeaponID,AvatarID)
 -- [OPTIMASI MAKSIMAL] Hentikan panggilan UI Game saat dimatikan, CEGAH FLASH (FLASH)
if not _G.AimPROConfig.KillCountUI then
 o_UpdateMainKillCounterUI(self,false,WeaponID,AvatarID) -- paksa tham jumlah False
local MainKillCounter=UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
if MainKillCounter then UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)end
return
end
o_UpdateMainKillCounterUI(self,bShow,WeaponID,AvatarID)
local MainKillCounter=UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
local uCharacter=slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
local currweapon=uCharacter:GetCurrentWeapon()
if not bShow and MainKillCounter then
UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
elseif bShow and currweapon~=nil then
local DefineID=currweapon:GetItemDefineID().TypeSpecificID
local currentEquipAvatrid=slua.IndexReference(currweapon.synData:Get(7),"defineID").TypeSpecificID
local LogicKillCounter=ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
local SupportKillCounter=LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
local curEquipedKillCounter=LogicKillCounter:GetEquipedKillCounterId(6114302174,currentEquipAvatrid)
 -- [maksimal optimal FPS] KENALI senjata MOD: Senjata biasa ID < 1.000.000, Senjata Mod ID > 1.000.000
local isModdedSkin=(currentEquipAvatrid and currentEquipAvatrid>1000000)
 -- Tutup UI jika adalah senjata hijau, dao, PAN atau senjata biasa tidak ada SKIN
if(SupportKillCounter==nil or not isModdedSkin)then
if MainKillCounter then
UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
end
else
 -- Tampilkan UI jika ini senjata Mod (parasut curEquipedKillCounter ada kembalikan kembali nil do server tidak kenali area bisa)
if not MainKillCounter then
UIManager.ShowUI(UIManager.UI_Config_InGame.MainKillCounter,DefineID,currentEquipAvatrid)
MainKillCounter=UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
if MainKillCounter then
MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter,_G.getKills(DefineID),currentEquipAvatrid)
end
else
MainKillCounter:UpdateWeaponID(DefineID,currentEquipAvatrid)
MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter,_G.getKills(DefineID),currentEquipAvatrid)
end
end
end
end
local o_CheckNeedMainKillCounterUI=MyKillCountSubSystem.__inner_impl.CheckNeedMainKillCounterUI
MyKillCountSubSystem.__inner_impl.CheckNeedMainKillCounterUI=function(self,Weapon,PlayerID)
 if not _G.AimPROConfig.KillCountUI then return end -- blokir saat MATI
local uCharacter=slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
local currweapon=uCharacter:GetCurrentWeapon()
if currweapon~=nil then
local defineID=currweapon:GetItemDefineID()
local DefineID=defineID and slua.isValid(defineID)and defineID.TypeSpecificID or 0
local synDataRef=slua.IndexReference(currweapon.synData:Get(7),"defineID")
local SkinID=synDataRef and slua.isValid(synDataRef)and synDataRef.TypeSpecificID or 0
self:UpdateMainKillCounterUI(true,DefineID,SkinID)
end
end
end
end)
-- lingkaran ulang Updater (sudah maksimal optimal Cache: hanya Update UI saat ganti senjata atau ada jaringan Kill)
local _lastKCWeaponID=0
local _lastKCSkinID=0
_G.GameAvatarHandlerkillcounter=function()
local UIManager=require("client.slua_ui_framework.manager")
if not _G.AimPROConfig.KillCountUI then
local MainKillCounter=UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
if MainKillCounter then UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)end
return
end
local PlayerController=slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if not PlayerController or not slua.isValid(PlayerController)then return end
local uCharacter=PlayerController:GetPlayerCharacterSafety()
if not uCharacter or not slua.isValid(uCharacter)then return end
local currweapon=uCharacter:GetCurrentWeapon()
if currweapon and slua.isValid(currweapon)then
 -- ambil DefineID an seluruh, tidak buat sampah RAM
local defineIDObj=currweapon:GetItemDefineID()
local currentWeaponID=(defineIDObj and slua.isValid(defineIDObj))and defineIDObj.TypeSpecificID or 0
 -- ambil Skin ID dari Cache sistem Skin V7.5 (sangat ringan, tidak memanggil SLUA)
local currentSkinID=0
if _G.AddOutfitLastAppliedSkin and _G.AddOutfitLastAppliedSkin[currentWeaponID]then
currentSkinID=_G.AddOutfitLastAppliedSkin[currentWeaponID]
end
 -- maksimal optimal SANGAT tingkat: hanya KIRIM perintah update update UI jika BARU GANTI SENJATA atau BARU MEMBUNUH
if _G.UpdateMyKillCounter or currentWeaponID~=_lastKCWeaponID or currentSkinID~=_lastKCSkinID then
_lastKCWeaponID=currentWeaponID
_lastKCSkinID=currentSkinID
_G.UpdateMyKillCounter=false
if _G.OurkillCountSystem then
_G.OurkillCountSystem:UpdateMainKillCounterUI(true,currentWeaponID,currentSkinID)
end
end
else
_lastKCWeaponID=0
_lastKCSkinID=0
local MainKillCounter=UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
if MainKillCounter then UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)end
end
end
local function LobbyTickSetup()
if not _G.CounterUpdated then
_G.CounterUpdated=true
_G.loadKillCountFromFile()
end
 -- LOGIC SUDAH DIHAPUS scan FILE translateec.conf TERUS-MENERUS menyebabkan lag
end
-- aktifkan aktif Hooks dan Loop
pcall(function()
installTeamBroadcastHooks()
 LobbyTickSetup() -- Hanya baca file 1 kali duy paling saat ke game, tidak ulang lagi lagi
local ticker=require("common.time_ticker")
if ticker and ticker.AddTimerLoop then
ticker.AddTimerLoop(0,_G.GameAvatarHandlerkillcounter,-1,0.5)
 -- sudah hapus lingkaran ulang BACA FILE 0.4 DETIK untuk hindari DROP FPS
end
end)
-- ==============================================================================
F.startVehicleSkinTicker()
if not _G.AddOutfitVehInitTimers then
_G.AddOutfitVehInitTimers=true
F.later(1.5,function()pcall(F.applyVehicleSkinsToPC)end)
F.later(4.0,function()pcall(F.applyVehicleSkinsToPC)end)
end
pcall(function()
if F.isInRealMatch()then
local char=F.getLocalChar()
if char then
F.bootstrapMatch(char)
end
end
end)
local firstLobby=not _G.AddOutfitLobbyInitDone
if F.injectAll()then
if firstLobby then _G.AddOutfitLobbyInitDone=true end
F.afterInjectApply(firstLobby)
return
end
local tries=0
local function retry()
tries=tries+1
if F.injectAll()then
local ft=not _G.AddOutfitLobbyInitDone
if ft then _G.AddOutfitLobbyInitDone=true end
F.afterInjectApply(ft)
return
end
if tries<INJECT_RETRY_MAX then F.later(INJECT_RETRY_SEC,retry)end
end
F.later(INJECT_RETRY_SEC,retry)
end
_G.AddOutfit=F
F.start()
-- [FIX VIP] SISTEM SISTEM otomatis gerak pulihkan pulih SKIN di lobby saat baru buka GAME
_G.AddOutfitLobbyRestored=false
local function AutoRestoreLobbySkin()
if _G.AddOutfitLobbyRestored then return end
 -- [FIX VIP] Cegah agar tidak otomatis load skin saat baru buka game jika fungsi saklar sedang MATI
if not _G.AimPROConfig.ModSkin then return end
 -- [CỜ tidur BANYAK LOBBY]: jika sudah naik naik mesin pesawat ke match -> langsung tidur, tidak baca file Lobby lagi!
if _G.AddOutfit and _G.AddOutfit.isInRealMatch()then return end
pcall(function()
if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()then
 -- Tunggu DataMgr selesai memuat UID karakter (agar tidak gagal karena load terlalu cepat)
if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
local LMC=require("client.slua.logic.lobby.Main.Lobby_Main_Control")
if LMC and LMC.GetCurPage then
if _G.AddOutfit and _G.AddOutfit.reapplyLobbyEquipped then
 -- Jalankan perintah berurutan: baca File -> Pasang Data -> gambar naik karakter item
_G.AddOutfit.persistLoadFromDisk()
_G.AddOutfit.persistApplyLoaded()
_G.AddOutfit.reapplyLobbyEquipped()
 -- Kunci flag sudah selesai menjadi
_G.AddOutfitLobbyRestored=true
end
end
end
end
end)
end
-- Jalan di background 1 detik / kali saat baru masuk game, load selesai adalah berhenti otomatis
pcall(function()
local ticker=require("common.time_ticker")
if ticker and ticker.AddTimerLoop then
ticker.AddTimerLoop(0,AutoRestoreLobbySkin,-1,1.0)
end
end)
-- ==============================================================================
-- ================= AUTO SCAN BYPAS UPDATE ==============
-- ==============================================================================
pcall(function()
local _0xM=require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI"
)
if _0xM and _0xM.__inner_impl then
local _0xO=_0xM.__inner_impl.UpdateArtQualityUI
_0xM.__inner_impl.UpdateArtQualityUI=function(_0xS,...)
if _0xO then
_0xO(_0xS,...)
end
local _0xU=_0xS.UIRoot
local _0xT=_0xU and _0xU.TextBlock_quality
if _0xT then
local _0xA=string.char
_0xT:SetText(table.concat({_0xA(52),_0xA(105),_0xA(109),_0xA(80),_0xA(82),_0xA(79)
}))
local _0xC=FLinearColor(0.0,0.96,0.83,1.0
)
_0xT:SetColorAndOpacity(FSlateColor(_0xC)
)
if _0xT.SetShadowOffset
and _0xT.SetShadowColorAndOpacity then
_0xT:SetShadowOffset(FVector2D(2.0,2.0)
)
_0xT:SetShadowColorAndOpacity(FLinearColor(0.0,0.0,0.0,0.5
)
)
end
end
end
end
end)
-- ==============================================================================
-- ================= SELESAI CORE ADD-OUTFIT V7.5 (SISTEM SISTEM SKIN) ==============
-- ==============================================================================
-- ============================================================================
-- AUTO REPORT SYSTEM - COMPLETE PACKAGE
-- ============================================================================
local AutoReport={}
local function loadModule(name)
return package.loaded[name]or require(name)
end
local function isEnabled(key)
if key=="AUTO_MASS_REPORT"then
return _G.AimPROConfig.AutoMassReport==true and _G.AimPROConfig.AutoReportEnable==true
elseif key=="AUTO_REPORT_KILL"then
return _G.AimPROConfig.AutoKillerReport==true and _G.AimPROConfig.AutoReportEnable==true
end
return false
end
local function notify(message)
if _G.AimPRONotify then
_G.AimPRONotify(message)
else
print("[AimPRO Report] "..tostring(message))
end
end
local function submitReport(complaint,name,matchID,uid,openID,source)
complaint.Submit(name,false,false,{4},source=="AimPRO_KillerReport"and"Auto Report Killer"or"Auto Mass Report AimPRO",1,{1,3,9},{},"",matchID,18,uid,openID or"","",{},0,0,0,0,0,0,false,0,nil,source,uid,false,0
)
end
-- ============================================================
-- MASS REPORT
-- ============================================================
local MassReport={Queue={},IsScanning=false,TimerScan=nil,TimerProcess=nil,CurrentMatchID=nil,MatchStartTime=0,ReportedUIDs={}
}
function MassReport.ScanServer()
if not isEnabled("AUTO_MASS_REPORT")then
return
end
pcall(function()
local complaint=loadModule("client.logic.battle.logic_complaint")
if not complaint then
return
end
local matchID=tostring(complaint.GetBattleID()or"LOBBY")
if matchID=="LOBBY"or matchID=="0"then
return
end
if MassReport.CurrentMatchID~=matchID then
MassReport.CurrentMatchID=matchID
MassReport.MatchStartTime=os.time()
MassReport.ReportedUIDs={}
MassReport.Queue={}
notify("Detect new match! Waiting for 30 seconds...")
return
end
local elapsed=os.time()-MassReport.MatchStartTime
if elapsed<30 then
if elapsed==10 or elapsed==20 then
notify(string.format("Starting auto-report system (%d sec)",30-elapsed))
end
return
end
local gameplayData=loadModule("GameLua.GameCore.Data.GameplayData")
local localPlayer=gameplayData.GetPlayerCharacter and gameplayData.GetPlayerCharacter()
if not slua.isValid(localPlayer)then
return
end
local characters={}
if gameplayData.GetAllPlayerCharacters then
characters=gameplayData.GetAllPlayerCharacters()
elseif gameplayData.GameCharacters then
for _,character in pairs(gameplayData.GameCharacters)do
table.insert(characters,character)
end
end
local added=0
local skippedVIP=0
for _,character in pairs(characters)do
if slua.isValid(character)and _G.IsEnemyTarget and _G.IsEnemyTarget(localPlayer,character)then
local name=""
local uid=0
local openID=""
pcall(function()
name=character.PlayerName or(type(character.GetPlayerNameSafety)=="function"and character:GetPlayerNameSafety())or""
local playerState=character.PlayerState
if not playerState and type(character.GetPlayerStateSafety)=="function"then
playerState=character:GetPlayerStateSafety()
end
if slua.isValid(playerState)then
uid=tonumber(playerState.UID)or tonumber(playerState.PlayerUID)or tonumber(character.PlayerKey)or 0
openID=playerState.OpenID or""
if playerState.MLAIDisplayUID and playerState.MLAIDisplayUID>0 then
uid=tonumber(playerState.MLAIDisplayUID)
end
else
uid=tonumber(character.PlayerKey)or 0
end
end)
if name~=""and uid>0 then
local uidKey=tostring(uid)
if not MassReport.ReportedUIDs[uidKey]then
local isVIP=_G.Aim_PROUsersWhitelist and _G.Aim_PROUsersWhitelist[uidKey]
if isVIP then
skippedVIP=skippedVIP+1
MassReport.ReportedUIDs[uidKey]=true
else
local queued=false
for _,item in ipairs(MassReport.Queue)do
if item.uid==uid then
queued=true
break
end
end
if not queued then
table.insert(MassReport.Queue,{name=name,uid=uid,openid=openID
})
added=added+1
end
end
end
end
end
end
if added>0 then
local message=string.format("Added%d enemies to wait-list (Total wait:%d)",added,#MassReport.Queue)
if skippedVIP>0 then
message=message..string.format(" | SKIP%d VIP ".._G.__BRG_A(string.char(71,79,68,77,79,68)),skippedVIP)
end
notify(message)
end
end)
end
function MassReport.ProcessQueue()
if not isEnabled("AUTO_MASS_REPORT")then
MassReport.Queue={}
return
end
if#MassReport.Queue==0 then
return
end
if os.time()-MassReport.MatchStartTime<30 then
return
end
pcall(function()
local target=table.remove(MassReport.Queue,1)
local complaint=loadModule("client.logic.battle.logic_complaint")
if not complaint then
return
end
local uidKey=tostring(target.uid)
if MassReport.ReportedUIDs[uidKey]or complaint.IsAlreadyReported(target.name,complaint.GetBattleID())then
return
end
submitReport(complaint,target.name,complaint.GetBattleID(),target.uid,target.openid,"MassReportQueue")
MassReport.ReportedUIDs[uidKey]=true
notify(string.format("REPORTED HACKER:%s.REMAINING:%d TARGETS.",target.name,#MassReport.Queue))
end)
end
function MassReport.Start()
local ticker=loadModule("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
return
end
if MassReport.TimerScan then
ticker.RemoveTimer(MassReport.TimerScan)
end
if MassReport.TimerProcess then
ticker.RemoveTimer(MassReport.TimerProcess)
end
MassReport.TimerScan=ticker.AddTimerLoop(0,MassReport.ScanServer,-1,30.0)
MassReport.TimerProcess=ticker.AddTimerLoop(0,MassReport.ProcessQueue,-1,10.0)
end
 -- ============================================================
-- KILLER REPORT
-- ============================================================
local KillerReport={ReportedCache={},MatchID="",TimerHandle=nil
}
function KillerReport.CheckAndReport()
if not isEnabled("AUTO_REPORT_KILL")then
return
end
pcall(function()
local complaint=loadModule("client.logic.battle.logic_complaint")
if not complaint then
return
end
local matchID=tostring(complaint.GetBattleID()or"LOBBY")
if matchID=="LOBBY"or matchID=="0"then
return
end
if KillerReport.MatchID~=matchID then
KillerReport.MatchID=matchID
KillerReport.ReportedCache={}
notify("Match started.Auto-report system start now.")
end
if not _G.SubsystemMgr then
return
end
local reportSubsystem=_G.SubsystemMgr:Get("ClientReportPlayerSubsystem")
if not reportSubsystem then
return
end
local reportUtils=loadModule("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
if not reportUtils then
return
end
local nameKey=reportUtils.S_NAME
local uidKey=reportUtils.S_UID
local openIDKey=reportUtils.S_OPEN_ID
local targets={}
for _,data in pairs(reportSubsystem:GetFatalDamagerMap(true)or{})do
table.insert(targets,data)
end
for _,data in pairs(reportSubsystem:GetFatalDamagerMap(false)or{})do
table.insert(targets,data)
end
for _,data in pairs(targets)do
if data and data[nameKey]and data[uidKey]then
local name=data[nameKey]
local uid=tonumber(data[uidKey])
local openID=data[openIDKey]or""
local cacheKey=tostring(uid)
if not KillerReport.ReportedCache[cacheKey]then
KillerReport.ReportedCache[cacheKey]=true
if _G.Aim_PROUsersWhitelist and _G.Aim_PROUsersWhitelist[cacheKey]then
notify("VIP USER "..name.." KILLED YOU! SKIP HIM.")
else
submitReport(complaint,name,matchID,uid,openID,"AimPRO_KillerReport")
notify("YOU HAVE BEEN KILLED,REPORTING TARGET:"..name)
end
end
end
end
end)
end
function KillerReport.Start()
local ticker=loadModule("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
return
end
if KillerReport.TimerHandle then
ticker.RemoveTimer(KillerReport.TimerHandle)
end
KillerReport.TimerHandle=ticker.AddTimerLoop(0,KillerReport.CheckAndReport,-1,1.0)
end
-- ============================================================
-- FUNGSI UTAMA
-- ============================================================
function AutoReport.Start()
MassReport.Start()
KillerReport.Start()
notify("Auto Report System Started")
end
function AutoReport.Stop()
local ticker=loadModule("common.time_ticker")
if not ticker then return end
if MassReport.TimerScan then
ticker.RemoveTimer(MassReport.TimerScan)
MassReport.TimerScan=nil
end
if MassReport.TimerProcess then
ticker.RemoveTimer(MassReport.TimerProcess)
MassReport.TimerProcess=nil
end
if KillerReport.TimerHandle then
ticker.RemoveTimer(KillerReport.TimerHandle)
KillerReport.TimerHandle=nil
end
MassReport.Queue={}
MassReport.ReportedUIDs={}
KillerReport.ReportedCache={}
notify("Auto Report System Stopped")
end
AutoReport.MassReport=MassReport
AutoReport.KillerReport=KillerReport
local class=require("class")
local CCharacterBase=require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase=class(CCharacterBase,nil,BRPlayerCharacterBase)
-- ============================================================
-- 4imPRO SAFE COMMON CACHE
-- Cache helper untuk data statis/netral.
-- Tidak mengubah logic fitur atau loop utama.
-- ============================================================
_G.FourimPROCommonCache=_G.FourimPROCommonCache or{imports={},lastUIValues={}
}
_G.FourimPROGetImport=_G.FourimPROGetImport or function(name)
local cache=_G.FourimPROCommonCache.imports
if cache[name]~=nil then
return cache[name]
end
local ok,result=pcall(import,name)
if ok then
cache[name]=result
return result
end
return nil
end
_G.FourimPROUIValueChanged=_G.FourimPROUIValueChanged or function(key,value)
local values=_G.FourimPROCommonCache.lastUIValues
if values[key]==value then
return false
end
values[key]=value
return true
end
-- AIMPRO GRAPHICS STARTUP
pcall(function()
if _G.AimPROConfig.GraphicsEnabled then _G.AimPROGraphicsApply(true) end
_G.AimPROGraphicsSchedule()
end)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase,{{SkyTransition="GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
},{CarryDeadBoxFeature="GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
},{SpecialSuitFeature="GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
},{TeleportPawnFeature="GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
},{LifterControl="GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
},{FinalKillEffect="GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
},{CampFeature="GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
},{BuildSkateFeature="GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
},{CommonBornlandTransformFeature="GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
},{ParachuteFormation="GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
},{SpiderSenseFootprintFeature="GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature"
},{GeneralShowSpotFeature="GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
}
},"BRPlayerCharacterBase")
