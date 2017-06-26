module kaleidic.email.vcard.loadfile;

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
import kaleidic.email.vcard.parse;

Vcard[][string] loadFile(string filename)
{
	auto text=(cast(string)(std.file.read(filename))).splitLines;
	
	int mode=0;
	string[] buf;
	string[] fieldList;
	Vcard[][string] cards;

	size_t unknownCount=0;

	foreach(line;text)
	{
		buf~=line;
		if (line.startsWith("END"))
		{
			auto card=buf.parseCard;
			Vcard[]* p;
			foreach (email;card.emails)
			{
				p = email.address in cards;
				if (p !is null)
					break;
			}
			if (p is null)
			{
				auto arr=[card];
				string email;
				if ((card.emails.length==0)||(card.emails[0].address.length==0))
				{
					email="unknown_"~unknownCount.to!string;
					unknownCount++;
				}
				else
				{
					email=card.emails[0].address;
				}
		
				cards[email]=arr;
			}
			else
			{
				(*p)~=card;
			}
			buf.length=0;
		}
	}
	return cards;
}
