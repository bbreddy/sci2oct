//  Author    :    B.Babu
//  Date      :    23rd May - 5th July
//  Place     :    IIT-Mumbai
//  Title     :    Scilab-Octave Interface

// Function name : sci2oct(-,-)
// Arguments     : Octave command, arguments(optional) 
// Return value  : Output of Octave command
// Description   : This is the main function in Scilab-Octave interface. It takes Octave command as valid Scilab string and its(Octave command) arguments. Then it writes that Octave commands in octFile. While writing it will call different functions based on argument data structure. After that it will call C function which gives octFile as input to Octave. Octave puts it's output in OctaveOutputTemp.txt. Other C function activates after that and removes unwanted characters in output and copies output to OctaveOutput.txt. Scilab reads output from OctaveOutput.txt and displays on it's own console. And it updates history depends on command.

function [answer] = sci2oct(x,varargin)
	funcprot(0)
	warning('off')
	octFile = mopen('octFile','wt');	
	mfprintf(octFile,'#! /usr/local/bin/octave -qf\n\n');
	nextIndex=checkForPkgLoad(x);
	mfprintf(octFile,'%s \n',getPkgs());	// getting packages
	mfprintf(octFile,'%s \n',getHistory());	 // getting history
	x=part(x,nextIndex:length(x));
	if(x=="exit")
		pkgs=mopen('pkgs','wt');
		close(pkgs);
		hiss=mopen('history','wt');
		close(hiss);
		answer="exited from Octave";
	end;	
	if(size(varargin)==0)
		expression(octFile,x);
	else		
		mfprintf(octFile,'%s(',x);
	end;
	for i=1:size(varargin)
		getType(octFile,varargin(i))
		if(i<>size(varargin))		
			mfprintf(octFile,',');
		end;
	end;
	if(size(varargin)<>0)
		mfprintf(octFile,')');
	end;
	mclose(octFile);
	call("sci2oct","out");
	try
		returnValue=fscanfMat('OctaveOutput.txt');
	catch
		try
			if(size(varargin)==0)
				returnValue=sci2octFull(x);
			else
				returnValue=sci2octFull(x,varargin);
			end;
		catch
			if(size(varargin)==0)
				returnValue=sci2octForStrings(x);
			else
				returnValue=sci2octForStrings(x,varargin);
				end;
		end;
	end;
	history = mopen('history','a');
	state=0;
	command="";	
	for i=1:length(x)
		//disp(state)
		select state
		case 0 then
			if(isletter(part(x,i)) | isnum(part(x,i)) | part(x,i)==' ')
				state=0;
				command=command+part(x,i);
			elseif(part(x,i)=='=')
				command=command+part(x,i);
				state=1;
			else
				command="";
			end;
		case 1 then
			if(part(x,i)==';' | part(x,i)=='\n')
				;			
			else
				command=command+part(x,i);
			end;
		end;
	end;
	// Here updating history depends on command. It updates only assignment commands.
	if(length(command)>0)
		if(size(varargin)<>0)
			mfprintf(history,'%s(',command);
			for i=1:size(varargin)
				getType(history,varargin(i))
				if(i<>size(varargin))		
					mfprintf(history,',');
				end;
			end;
			mfprintf(history,');\n');
		else
			mfprintf(history,'%s;\n',command);
		end;
		
	end;
	mclose(history);
	mclose('all');
	answer=returnValue;
endfunction;

// Function name : getPkgs()
// Arguments     : None 
// Return value  : all "pkg load" & "symbols" instructions
// Description   : It writes all "load pkg" & "symbols" instructions to octFile from "pkgs" file
function [pkgs] = getPkgs()
	funcprot(0)
	fileDetails = fileinfo('pkgs');
	pkg = mopen('pkgs','rt');
	pkgs = mgetstr(fileDetails(1),pkg);
	mclose(pkg);
endfunction;

// Function name : getHistory()
// Arguments     : None 
// Return value  : Recent assignment commands.
// Description   : It reads history file and returns history 
function [history] = getHistory()
	funcprot(0)
	fileDetails = fileinfo('history');
	his = mopen('history','rt');
	history = mgetstr(fileDetails(1),his);
	mclose(his);
endfunction;

// Function name : checkForPkgLoad()
// Arguments     : None 
// Description   : It extracts "pkg load" and "symbols" instructions from Octave command and stores in pkgs file for future purpose.
// Return Value  : nextIndex(index in Octave command after "pkg load" or "symbols"  instruction)

function [nextIndex] = checkForPkgLoad(x)
	funcprot(0)
	pkgs=mopen('pkgs','a');
	i=0;	
	for i=1:length(x)
		if(part(x,i)<>' ')
			break;
		end;
	end;
	j=i;
	k=j;
	if(part(x,i:i+2)=='pkg')
		for k=(i+3):length(x)
			if(part(x,k)<>" ")
				break;
			end;
		end;
		if(part(x,k:k+3)=='load')
			for k=k+4:length(x)
				if(part(x,k)<>" ")
					break;
				end;
			end;
			for k=k:length(x)
				if(part(x,k)==' ' | part(x,k)=="\n" | part(x,k)==';' )
					break;
				end;
			end;
		if(part(x,k)==';')
			mfprintf(pkgs,'%s \n',part(x,j:k));
		else
			mfprintf(pkgs,'%s; \n',part(x,j:k));
		k=k+1;		
		end;		
		end;
	elseif(part(x,i:i+6)=='symbols')
		mfprintf(pkgs,'%s \n','symbols;');
		k=i+7;	
	end;
	close(pkgs);
	nextIndex=k;
endfunction;

// Function name : sci2octFull(-,-)
// Arguments     : Octave command, arguments(optional) 
// Return value  : Output of Octave command
// Description   : It is similar to "sci2oct" function but it works for Octave functions which returns sparse matrix as output.
function [returnValue] = sci2octFull(x,varargin)
	octFile = mopen('octFile','wt');
	mfprintf(octFile,'#! /usr/local/bin/octave -qf \n');
	mfprintf(octFile,'%s \n',getPkgs());	
	mfprintf(octFile,'%s \n',getHistory());
	if(size(varargin)==0)
		mfprintf(octFile,'full(');
		expression(octFile,x);
	else		
		mfprintf(octFile,'full(%s(',x);
	end;
	if(size(varargin)<>0)	
		for i=1:size(varargin(1))
			getType(octFile,varargin(1)(i))
			if(i<>size(varargin(1)))		
				mfprintf(octFile,',');
			end;
		end;
	end;
	if(size(varargin)<>0)
		mfprintf(octFile,'))');
	else
		mfprintf(octFile,')');
	end;
	mclose(octFile);
	call("sci2oct","out");
	returnValue=fscanfMat('OctaveOutput.txt');
	returnValue=sparse(returnValue);
	mclose('all');	
endfunction

// Function name : sci2octForStrings(-,-)
// Arguments     : Octave command, arguments(optional) 
// Return value  : Output of Octave command
// Description   : It is similar to "sci2oct" function but it works for Octave functions which returns string matrix as output.
function [ret2] = sci2octForStrings(x,varargin)
	octFile = mopen('octFile','wt');
	mfprintf(octFile,'#! /usr/local/bin/octave -qf\n\n');
	mfprintf(octFile,'%s \n',getPkgs());
	mfprintf(octFile,'%s \n',getHistory());
	if(size(varargin)==0)
		expression(octFile,x);
	else		
		mfprintf(octFile,'%s(',x);
	end;
	if(size(varargin)<>0)	
		for i=1:size(varargin(1))
			getType(octFile,varargin(1)(i))
			if(i<>size(varargin(1)))		
				mfprintf(octFile,',');
			end;
		end;
	end;	
	if(size(varargin)<>0)
		mfprintf(octFile,')');
	end;
	mclose(octFile);
	call("sci2oct","out");
	fileDetails = fileinfo('OctaveOutput.txt');
	output = mopen('OctaveOutput.txt','rt');
	ret2 = mgetstr(fileDetails(1),output);
	ret2=part(ret2,1:length(ret2)-1); // removing last new line
	mclose(output);
	mclose('all');
endfunction
// Function name : expression(-,-)
// Arguments     : file descriptor, expression 
// Return value  : None
// Description   : It prints expressions in octFile. It gets Scilab variable values using eval() function 
function[] = expression(fd,str)
	name='';
	char1='';
	specialChar='';
	specialChars={'!','@','#','$','%','%','^','&','*','(',')','-','_','+','=','\','|','[',']','{','}',"''",'""',':',';','.',',','>','<','?','/',' '};
	last=0;	
	for i=1:length(str)
		char1 = part(str,i);
		name=name+char1;		
		for j=1:32
			if(specialChars(j)==char1)
					last=i;			
					if(length(name)>=2)
						if execstr(part(name,1:length(name)-1),'errcatch')<>0 then
						   mfprintf(fd,'%s',name);
						else
						   value=eval(part(name,1:length(name)-1));
						   getType(fd,value);
						   mfprintf(fd,'%s',char1);
						end
					else
						mfprintf(fd,'%s',char1);
					end;
			name='';
			break;			
			end;		
		end;

	end;
	if(last<>length(str))
		if execstr(name,'errcatch')<>0 then
		   mfprintf(fd,'%s',name);
		else
		   value=eval(name);
		   getType(fd,value);
		end;
	end;
endfunction;
// Getting the type of arguments
function [] = getType(fd,arg)
	if type(arg)==1 then //
		printType1(fd,arg)
	elseif type(arg)==10 then // character matrix
		printType10(fd,arg) 
	elseif type(arg)==4 then // boolean matrix
		printType4(fd,arg)
	elseif type(arg)==5 then // sparse matrix
		printType5(fd,full(arg))
	elseif type(arg)==6 then // boolean matrix
		printType4(fd,full(arg))
	elseif type(arg)==15 then // list
		printType15(fd,arg)
	else
		error "Equivalent data structure not found in Octave";
	end;
endfunction;

// Function to print Type 1 : real or complex constant matrix.
function [] = printType1(fd,Matrix)
	printMatrix(fd,'%f',Matrix);
endfunction

// Function to print Type51 : real or complex constant sparse matrix.
function [] = printType5(fd,Matrix)
	printMatrix(fd,'%f',Matrix);
endfunction

// Function to print Type 10 : matrix of character strings.
function [] = printType10(fd,stringMatrix)
	printMatrix(fd,'%s',stringMatrix);
endfunction
// To print matrix on file
function [] = printMatrix(fd,stringConstant,Matrix)
	[rows,cols]=size(Matrix);
	//columnNumber=1;
	if(rows>1 | cols>1) then
		mfprintf(fd,'[');
	end;
	for i=1:rows
		rowNumber=0;
		for j=1:cols
			if(stringConstant=='%s') then
				printString(fd,Matrix(i+rowNumber));
			else
				mfprintf(fd,stringConstant,Matrix(i+rowNumber));
			end			
			rowNumber=rowNumber+rows;
			if(j<>cols) then
				mfprintf(fd,',');
			end			
		end;
		if(i<>rows) then		
			mfprintf(fd,';');
		//columnNumber=columnNumber+rows;
		end	
	end;	
	if(rows>1 | cols>1) then
		mfprintf(fd,']');
	end
endfunction

// Function to print individual string
function [] = printString(fd,String)
	mfprintf(fd,'""');
	mfprintf(fd,String)
	mfprintf(fd,'""');
endfunction

// For boolean matrix
function [] = printType4(fd,booleanMatrix)
	[rows,cols]=size(booleanMatrix);
	//columnNumber=1;
	if(rows>1 | cols>1) then
		mfprintf(fd,'[');
	end	
	for i=1:rows
		rowNumber=0;
		for j=1:cols
			if(booleanMatrix(i+rowNumber)) then
				mfprintf(fd,'%s','true');
			else
				mfprintf(fd,'%s','false');	
			end;		
			rowNumber=rowNumber+rows;
			if(j<>cols) then
				mfprintf(fd,',');
			end;			
		end;
		if(i<>rows) then		
			mfprintf(fd,';');
		//columnNumber=columnNumber+rows;
		end	
	end;	
	if(rows>1 | cols>1) then
		mfprintf(fd,']');
	end
endfunction

// For lists
function [] = printType15(fd,List)
	Size = size(List)
	mfprintf(fd,'{');
	for i=1:Size
		getType(fd,List(i));
		if(i<>Size)
			mfprintf(fd,',');
		end;
	end;	
	mfprintf(fd,'}');
endfunction
