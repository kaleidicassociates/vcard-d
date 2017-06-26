module kaleidic.email.vcard.parse;

/**

	Simple utility to parse Vcards and extract information to D struct
	(c) 2015 Laeeth Isharc and Kaleidic Associates Advisory Limited
	Use at your own risk: pre-alpha
	Only tested on my own contacts (a few thousand)
*/

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.array:array;
import std.traits:EnumMembers;
import std.conv:to;

enum ContactTypeMajor
{
	home,
	work,
	cell,
	pager,
	other
}

enum TelType
{
	na,
	voice,
	fax,
}

struct ContactType
{
	ContactTypeMajor major;
	TelType tel;
}

struct EmailAddress
{
	ContactType type;
	string address;
}

struct TelNo
{
	ContactType type;
	string number;
}

struct Address
{
	ContactType type;
	string address;
}

struct Vcard
{
	Address[] addresses;
	EmailAddress[] emails;
	TelNo[] tels;

	string bday;
	string caluri;
	string class_;
	string fburl;
	string label;
	string nickname;
	string note;
	string org;
	string prodid;
	string rev;
	string role;
	string title;
	string uid;
	string version_;
	string evolutionAssistant;
	string evolutionBlogUrl;
	string evolutionManager;
	string evolutionSpouse;
	string evolutionVideoUrl;
	string evolutionWebdavHref;
	string evolutionFileAs;
	string mozillaHtml;
	string radicaleName;
	string fn;
	string labels;
	string[] items;
	string xAbLabel;
	string url;
	string n;
}

struct ParsedField
{
	string key;
	string value;
}

ParsedField parseField(string line)
{
	ParsedField ret;
	auto i=line.indexOf(":");
	if (i==-1)
		return ret;
	auto key=line[0..i];
	if (i==line.length)
		return ParsedField(key,"");
	return ParsedField(key,line[i+1..$]);
}

string parseFieldStub(string line)
{
	auto i=line.indexOf(";");
	auto j=line.indexOf(":");
	if ((i==-1) && (j==-1))
		return line;

	if (i==-1)
		return line[0..j];
	if (j==-1)
		j=i;
	return line[0..min(i,j)];
}

EmailAddress parseEmail(string str)
{

	return EmailAddress(str.parseContactType,str.parseField.value);
}

Address parseAddress(string str)
{

	return Address(str.parseContactType,str.parseField.value);
}

TelNo parseTel(string str)
{
	return TelNo(str.parseContactType,str.parseField.value);
}


ContactType parseContactType(string line)
{
	ContactType ret;
	string saveLine=line.idup;
	line=line.strip;
	auto z=line.indexOf(";");
	bool isEmail=(line.startsWith("EMAIL") || ((z>-1) && (line[0..z].endsWith("EMAIL"))));
	auto i=line.indexOf("TYPE=");
	if (i==-1)
		return ret;
	i+="TYPE=".length;

	line=line[i..$];
	auto j=line.indexOf(":");
	if(j==-1)
		return ret;

	line=line[0..j];
	auto fields=line.split(",");

	string relevantField;	
	string relevantSubfield;

	if (isEmail && fields[0]=="INTERNET")
		relevantField=(fields.length>1?fields[1].toLower:"other");
	else
	{
		relevantField=fields[0];
		if (fields.length>1)
			relevantSubfield=fields[1..$].join(",").toLower;
	}

	
	auto type=relevantField.strip.toLower;

	foreach(entry;EnumMembers!ContactTypeMajor)
	{
		if(entry.to!string==type)
		{
			if (!isEmail && relevantSubfield.length>0)
			{
				if (relevantSubfield=="voice")
					ret.tel=TelType.voice;
				else if (relevantSubfield=="fax")
					ret.tel=TelType.fax;
				else
					stderr.writefln("ignoring telephone field: %s for %s",relevantSubfield, saveLine);
			}
			ret.major=entry;
			return ret;
		}
	}
	stderr.writefln("ignoring unknown field type: %s for %s", relevantField, saveLine);
	return ret;
}
	



Vcard parseCard(string[] card)
{
	Vcard ret;
	foreach(line;card)
	{
		auto field=line.parseField;
		
		switch(line.parseFieldStub.strip)
		{
			case "ADR":
				ret.addresses~=line.parseAddress;
				break;
			case "BDAY":
				ret.bday=field.value;
				break;
			case "BEGIN","END":
				break;
			case "CALURI":
				ret.caluri~=field.value;
				break;
			case "CLASS":
				ret.class_~=field.value;
				break;
			case "EMAIL","item1.EMAIL","item2.EMAIL","item3.EMAIL":
				ret.emails~=line.parseEmail;
				break;
			case "FN":
				ret.fn~=field.value;
				break;
			case "FBURL":
				ret.fburl~=field.value;
				break;
			case "LABEL":
				ret.labels~=field.value;
				break;
			case "NICKNAME":
				ret.nickname~=field.value;
				break;
			case "NOTE":
				ret.note~=field.value;
				break;
			case "ORG":
				ret.org~=field.value;
				break;
			case "PRODID":
				ret.prodid~=field.value;
				break;
			case "REV":
				ret.rev~=field.value;
				break;
			case "ROLE":
				ret.role~=field.value;
				break;
			case "TEL":
				ret.tels~=line.parseTel;
				break;
			case "TITLE":
				ret.title~=field.value;
				break;
			case "UID":
				ret.uid~=field.value;
				break;
			case "URL","item1.URL","item2.URL","item3.URL":
				ret.url~=field.value;
				break;
			case "VERSION":
				ret.version_~=field.value;
				break;
			case "item1.X-ABLabel","item2.X-ABLabel","item3.X-ABLabel":
				ret.xAbLabel~=field.value;
				break;
			case "X-EVOLUTION-ASSISTANT":
				ret.evolutionAssistant~=field.value;
				break;

			case "X-EVOLUTION-BLOG-URL":
				ret.evolutionBlogUrl~=field.value;
				break;
			case "X-EVOLUTION-FILE-AS":
				ret.evolutionFileAs~=field.value;
				break;
			case "X-EVOLUTION-MANAGER":
				ret.evolutionManager~=field.value;
				break;
			case "X-EVOLUTION-SPOUSE":
				ret.evolutionSpouse~=field.value;
				break;
			case "X-EVOLUTION-VIDEO-URL":
				ret.evolutionVideoUrl~=field.value;
				break;
			case "X-EVOLUTION-WEBDAV-HREF":
				ret.evolutionWebdavHref~=field.value;
				break;
			case "X-MOZILLA-HTML":
				ret.mozillaHtml=field.value;
				break;
			case "X-RADICALE-NAME":
				ret.radicaleName~=field.value;
				break;
			case "N":
				ret.n=field.value;
				break;
			default:
				stderr.writefln("unhandled: %s",line);
				stderr.writefln("***%s",line.parseFieldStub.strip);
				break;
		}
	}
	return ret;
}


string[] fields(string[] buf)
{
	string[] ret;
	foreach(line;buf)
	{
		auto i=line.indexOf(":");
		if (i>1)
			ret~=line[0..i];	
	}
	return ret;
}
