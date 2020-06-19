import os
from subprocess import Popen, PIPE, STDOUT
import matplotlib.pyplot as plt

if __name__ == "__main__":
  methods = ["tahoe", "newreno", "vegas"]
  colors = {"tahoe": 'teal', "newreno": 'violet', "vegas": 'orange'}
  params = ["cwnd", "goodput"]
  labels = []
  paramVal = dict()
  for p in params:
    paramVal[p] = dict()
    for m in methods:
      paramVal[p][m] = dict()
      for f in range(1,3):
        paramVal[p][m][f] = dict()
  for method in methods:
    os.environ["METHOD"] = method
    for i in range(10):
      os.system("ns core.tcl")
      for flow in range(1,3):
        for param in params:
          f = open(param + str(flow) + ".txt")
          lines = f.readlines()
          for line in lines:
            splitted = line.split(' ')
            if splitted[0] in paramVal[param][method][flow]:
              paramVal[param][method][flow][splitted[0]] += float(splitted[1])
            else:
              paramVal[param][method][flow][splitted[0]] = 0.0
          f.close()
  for param in params:
    plt.figure(figsize=(20,20))
    plt.title(param)
    for method in methods:
      for flow in range(1,3):
        paramVal[param][method][flow] = {key: paramVal[param][method][flow][key] / 10 for key in paramVal[param][method][flow]}
        labels.append(method + " - flow" + str(flow))
        linestyle = 'solid'
        if (flow == 2):
          linestyle = 'dashed'
        lists = paramVal[param][method][flow].items()
        x, y = zip(*lists) 
        plt.plot(x, y, colors[method], linestyle=linestyle)
    plt.xlabel("time")
    plt.ylabel("parameter value")
    plt.xticks(rotation=90)
    plt.legend(labels, loc='upper left')
    plt.savefig(param + ".png")
  plt.show()
