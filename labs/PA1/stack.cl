(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)
class Stack 
{
   isEmpty(): Bool { true };
   top(): String { {abort(); "0"; } };
   pop(): Stack { {abort(); self;} };
   push(str: String): Stack {
      (new Cons).init(str,self)
   };
};

class Cons  inherits Stack
{
   car : String;
   cdr : Stack;
   isEmpty(): Bool { false };
   pop(): Stack {
      cdr
   };
   top(): String {
      car
   };
   init(str: String, rest: Stack): Stack 
   {
     {
      car <- str;
      cdr <- rest;
      self;
     }
   };
};

class StackCommand
{
   commandStr: String;
   doCommand(myStack : Stack): Stack {
      myStack.push(commandStr)
   };
   init(str: String): SELF_TYPE {
      {
         commandStr <- str;
         self;
      }
   };
};

class DisplayCommand inherits StackCommand {
   doCommand(myStack : Stack): Stack {
      {
         let temp: Stack <- myStack in 
         {
            while not temp.isEmpty() loop
            {
              new IO.out_string(temp.top()).out_string("\n");
               temp <- temp.pop();
            }
            pool;
         };
         myStack;
      }
   };
};

class StopCommand inherits StackCommand {
   nullStack: Stack;
   doCommand(myStack: Stack): Stack {
      nullStack
   };
};

class EvaluateCommand inherits StackCommand {
   doCommand(myStack: Stack): Stack {
      if not myStack.isEmpty() then
         let temp:String <- myStack.top() in
         {
            if temp = "+" then
            {
               myStack <- myStack.pop();
               let first_value: String <- myStack.top(), tool: A2I <- new A2I in
               {
                  myStack <- myStack.pop();
                  let second_value: String <- myStack.top() in
                  {
                     myStack <- myStack.pop();
                     myStack <- myStack.push( tool.i2a(tool.a2i(first_value) +  tool.a2i(second_value)));
                  };
               };
               myStack;
            }
            else if temp = "s" then
            {
               myStack <- myStack.pop();
               let first_value: String <- myStack.top(), tool: A2I <- new A2I in
               {
                  myStack <- myStack.pop();
                  let second_value: String <- myStack.top() in
                     {
                        myStack <- myStack.pop();
                        myStack <- myStack.push(first_value).push(second_value);
                     };
               };
               myStack;
            }
            else
               myStack
            fi fi;
         }
      else
         myStack
      fi
   };
};

class StackCommandFactory {
   getCommand(str : String): StackCommand {
      if str = "d" then new DisplayCommand.init(str) else
      if str = "x" then new StopCommand.init(str) else
      if str = "e" then new EvaluateCommand.init(str) else
         new StackCommand.init(str)
      fi fi fi
   };
};

class Main inherits IO {
   myStack: Stack <- new Stack;
   commandFactory: StackCommandFactory <- new StackCommandFactory;
   main() : Object {
      while not isvoid myStack loop
      {
         out_string(">");
         myStack <- commandFactory.getCommand(in_string()).doCommand(myStack);
      }
      pool
   };

};
