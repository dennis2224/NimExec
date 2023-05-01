import std/os
import system
import net
import OptionsHelper
import Structs
import Packets


when isMainModule:
    PrintBanner()
    var optionsStruct:OPTIONS
    if(not ParseArgs(paramCount(),commandLineParams(),addr optionsStruct)):
        PrintHelp() 
        quit(0)
    var messageID:uint64 = 0
    var treeID:array[4,byte]
    var sessionID:array[8,byte]
    if(optionsStruct.Domain != ""):
        optionsStruct.OutputUsername = optionsStruct.Domain & "\\" & optionsStruct.Username
    else:
        optionsStruct.OutputUsername = optionsStruct.Username
    var targetBytesInWCharForm:WideCStringObj = newWideCString(optionsStruct.Target) # .len property doesn't count its double null bytes, and it doesn't
    # var test = targetBytesInWCharForm.len
    # var test2:array[4,byte]
    # copyMem(addr test2[0],addr targetBytesInWCharForm[0],6)
    var tcpSocket:net.Socket = newSocket(buffered=false)
    var smbNegotiateFlags:seq[byte] = @[byte 0x05, 0x80, 0x08, 0xa0]
    var smbSessionKeyLength:seq[byte] = @[byte 0x00, 0x00]
    try:
        tcpSocket.connect(optionsStruct.Target,Port(445),60000)
    except CatchableError:
        var e = getCurrentException()
        var msg = getCurrentExceptionMsg()
        echo "[!] Got exception ", repr(e), " with message ", msg
        quit(0)
    if(optionsStruct.IsVerbose):
        echo "[+] Connected to ", optionsStruct.Target, ":445"
    if(not NegotiateSMB2(tcpSocket,addr messageID,addr treeID, addr sessionID)):
        echo "[!] Problem in NegotiateSMB2 request!"
        quit(0)
    if(not NTLMSSPNegotiateSMB2(tcpSocket,addr optionsStruct,smbNegotiateFlags,smbSessionKeyLength,addr messageID,addr treeID, addr sessionID)):
        echo "[!] Problem in NTLMSSPNegotiateSMB2 request!"
        quit(0)
    if(optionsStruct.IsVerbose):
        echo "[+] NTLM Authentication with Hash is succesfull!"
    
    
    