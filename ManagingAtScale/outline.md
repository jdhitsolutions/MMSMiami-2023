# Managing at Scale with PowerShell: Unlocking the Power of the Pipeline

75 minutes plus 10-15 minutes Q/A

## Sequential vs Scale

+ NO RDP!!
+ Legacy connections don't scale
+ Do it for 1 do it for 1000
+ PowerShell is NOT always the answer

## Where is Your Code?

+ What command is running?
+ Where is it running?
+ Where is the output?
+ What are you doing with the output?
  + Action or Archive
  + How critical is performance?

## Filtering

+ Early vs Late filtering
+ Filtering parameters

## Variables, Arrays, and Collections

+ Using standard arrays
+ Using generic collections
+ Using OutVariable
+ Using PipelineVariable

## Leverage Remoting

+ Using Temporary connections
+ Using CIM and PSSessions
+ Remoting challenges
  + Credentials
  + 2nd Hop
  + Error handling

## Parallel Processing

+ Remoting with Invoke-Command
+ Background Jobs
+ Thread Jobs
+ ForEach-Object -parallel
+ Synchronized Runspaces

## Cross-Platform Scripting

+ Managing platform differences
+ Remoting challenges

## Demo

## Scripting at Scale Best Practices

+ Include computername
+ Include throttling
+ Watch property types
+ Consider metadata
+ Log when necessary

## Questions and Answers
