import os
import matplotlib.pyplot as plt
import math

if __name__ == "__main__":
  methods = ["tahoe", "newreno", "vegas"]
  colors = {"tahoe": 'teal', "newreno": 'magenta', "vegas": 'orange'}
  params = ["cwnd", "goodput", "drop"]
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
          if (param == "drop"):
            f = open("out.tr")
            lines = f.readlines()
            for line in lines:
              splitted = line.split(' ')
              if (splitted[0] != 'd'):
                continue
              if (splitted[1] not in paramVal[param][method][flow]):
                paramVal[param][method][flow][int(math.ceil(float(splitted[1]) / 10.0)) * 10] = 1.0
              if (((flow == 1) and ([splitted[8], splitted[9]] == ['0.0', '4.0'] or
              [splitted[8], splitted[9]] == ['4.0', '0.0'])) or 
              ((flow == 2) and ([splitted[8], splitted[9]] == ['1.0', '5.0'] or
              [splitted[8], splitted[9]] == ['5.0', '1.0']))):
                paramVal[param][method][flow][int(math.ceil(float(splitted[1]) / 10.0)) * 10] += 1.0
            f.close()
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
    markers = ['v', 'X', 'P', 's', 'o', 'D']
    plt.figure(figsize=(20,16))
    plt.title(param)
    for method in methods:
      for flow in range(1,3):
        paramVal[param][method][flow] = {key: paramVal[param][method][flow][key] / 10 for key in paramVal[param][method][flow]}
        labels.append(method + " - flow" + str(flow))
        linestyle = 'solid'
        if (flow == 2):
          linestyle = 'dashed'
        lists = paramVal[param][method][flow].items()
        if len(lists) == 0:
          x = list(range(1001))
          y = [0 for _ in range(1001)]
        else:
          x, y = zip(*lists) 
        plt.plot(x, y, colors[method], marker=markers.pop(), linestyle=linestyle)
    plt.xlabel("time")
    plt.ylabel("parameter value")
    plt.xticks(rotation=90)
    plt.legend(labels, loc='upper left')
    plt.savefig(param + ".png")
  plt.show()
