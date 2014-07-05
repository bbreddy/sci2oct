// This program removes unwanted characters(like ans = ) from Octave output.
#include<string.h>
#include<stdio.h>
#include <stdlib.h>
void removeFirstCharacters()
{
	//system("sed -e '1,18d' > OctaveOutputTemp.txt < octaveOut1.txt");
	//system("rm octaveOut1.txt");sc
	char filename[100]="OctaveOutputTemp.txt";
	char file2name[100] = "OctaveOutput.txt";
	FILE *file;
	FILE *file1;
	FILE *write;
	char ch; 
       	file = fopen(filename, "r" );
 	file1 = fopen(filename, "r" );
       	write = fopen(file2name, "w" );
	int newLine=0,equal=0,eof=0,space=0;
	while(ch=fgetc(file))
	{
		if(ch==' ')
			space++;
		if(space==2)
		{
			newLine=1;
			break;
			}
		if(ch=='\n'),
		{
			newLine=1;
			break;
			}
		else if(ch=='=')
		{
			equal=1;
			break;
			}
		else if(ch==EOF)
		{
			eof=1;
			break;
			}
		}
	if(equal)
	{
		ch=fgetc(file);
		while((ch=fgetc(file))!=EOF)
		{
		    fputc(ch,write);
		    }
		}
	if(newLine)
	while((ch=fgetc(file1))!=EOF)
	{
	    fputc(ch,write);
	    }
	close(file);
	close(file1);
	close(write);	
	system("rm OctaveOutputTemp.txt");
}
void runOctave() // Activates Octave to take input
{
	system("octave -qf octFile > OctaveOutputTemp.txt");
}
int main()
{ 
	runOctave();
	removeFirstCharacters();
	return 0;
}
