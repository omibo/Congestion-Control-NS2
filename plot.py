import os
import matplotlib.pyplot as plt
import math
import numpy as np

def plot(timeIncr = 1):
  methods = ["tahoe", "newreno", "vegas"]
  params = ["cwnd", "goodput", "rtt", "dropRate"]
  labels = []
  paramVal = dict()
  for p in params:
    paramVal[p] = dict()
    for m in methods:
      paramVal[p][m] = dict()
      for f in range(1,3):
        paramVal[p][m][f] = dict()
  os.environ["TIMEINCR"] = str(timeIncr)
  for method in methods:
    os.environ["METHOD"] = method
    for i in range(10):
      os.system("ns core.tcl")
      dropRates = calcDropRate("out.tr", timeIncr)
      for flow in range(1,3):
        for param in params:
          if (param == "dropRate"):
            for i in range(len(dropRates[flow - 1])):
              if (i * timeIncr) in paramVal[param][method][flow]:
                paramVal[param][method][1][i * timeIncr] += dropRates[flow - 1][i]
              else:
                paramVal[param][method][1][i * timeIncr] = dropRates[flow - 1][i]
          else:
            f = open(param + str(flow) + ".txt")
            lines = f.readlines()
            for line in lines:
              splitted = line.split(' ')
              if splitted[0] in paramVal[param][method][flow]:
                paramVal[param][method][flow][splitted[0]] += float(splitted[1])
              else:
                paramVal[param][method][flow][splitted[0]] = float(splitted[1])
            f.close()
  for param in params:
    colors = ['deeppink', 'darkviolet', 'crimson', 'lime', 'orange', 'lightseagreen']
    plt.figure(figsize=(20,16))
    plt.title(param)
    for method in methods:
      for flow in range(1,3):
        paramVal[param][method][flow] = {key: paramVal[param][method][flow][key] / 10 for key in paramVal[param][method][flow]}
        labels.append(method + " - flow" + str(flow))
        linestyle = 'solid'
        lists = paramVal[param][method][flow].items()
        if len(lists) == 0:
          x = list(range(1001))
          y = [0 for _ in range(1001)]
        else:
          x, y = zip(*lists) 
        plt.xticks(np.arange(0, 1100, 100 / timeIncr))
        plt.plot(x, y, colors.pop(), linestyle=linestyle)
    plt.xlabel("time")
    plt.ylabel("parameter value")
    plt.legend(labels, loc='upper left')
    plt.savefig(param + ".png")
  print(" 100%")
  plt.show()

def calcDropRate(fileName, timeIncr = 1):
  step = timeIncr
  dropRate1 = list()
  dropRate2 = list()
  dropNum1 = 0
  dropNum2 = 0

  lastTime = step
  with open(fileName) as traceFile:
    for line in traceFile:
      eventRecordFields = line.split()
      status = eventRecordFields[0]
      time = float(eventRecordFields[1])
      if time>lastTime:
        dropRate1.append(dropNum1)
        dropRate2.append(dropNum2)
        dropNum1 = 0
        dropNum2 = 0 
        lastTime = int(time) + step
      flowId = eventRecordFields[7]

      if status == 'd':
        if flowId == '1':
          dropNum1 += 1
        elif flowId == '2':
          dropNum2 += 1

  return dropRate1, dropRate2


if __name__ == "__main__":
  plot(timeIncr = 1)
