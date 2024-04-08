# E-VRPTW

CPLEX code of the Electric Vehicle-routing Problem with Time Windows (E-VRPTW) and recharging stations based on the paper of Schneider et al (2014)

https://doi.org/10.1287/trsc.2013.0490

Abstract: Given by new laws and regulations concerning the emission of greenhouse gases, carriers are starting to use electric vehicles for last-mile deliveries. The limited battery capacities of these vehicles necessitate visits to recharging stations during delivery tours of industry-typical length, which have to be considered in the route planning to avoid inefficient vehicle routes with long detours. We introduce the electric vehicle- routing problem with time windows and recharging stations (E-VRPTW), which incorporates the possibility of recharging at any of the available stations using an appropriate recharging scheme. Furthermore, we consider limited vehicle freight capacities as well as customer time windows, which are the most important constraints in real-world logistics applications. As a solution method, we present a hybrid heuristic that combines a variable neighborhood search algorithm with a tabu search heuristic. Tests performed on newly designed instances for the E-VRPTW as well as on benchmark instances of related problems demonstrate the high performance of the heuristic proposed as well as the positive effect of the hybridization.



## Update

Since the previous code was done a long time ago for a different purpose, and it is **based** on the paper of Schneider et al (2014), Zheng detected the running results are inconsistent. Thanks to Jônatas Augusto Manzolli's invitation, Zheng contributes to this code.

There are three bugs in the previous code:

1. The distance calculation should not only retain one decimal place, as there is a large accuracy error.
2. The cplex code does not optimize the number of vehicles first and then optimize the total distance.
3. The recharging station does not have a set copy, which is inconsistent with "a set of dummy vertices generated to permit several visits to each vertex in the set F of recharging stations" in the paper.

The updated content is as follows:

1. delete E-VRPTW.dat,  E-VRPTW.ops

2. add folder `E-VRPTW Instances - CPLEX data` which includes all E-VRPTW Instances with ".dat" format  (For simplicity, we just **set two copies** for each charging station, and CPLEX is employed to solve the MIP formulation) 

3. update E-VRPTW.mod:

   1. update the distance calculation: 

      ```AMPL
      d[i][j] = Math.sqrt(Math.pow(XCoord[i]-XCoord[j], 2) + Math.pow(YCoord[i]-YCoord[j], 2));
      ```

   2. as the paper of Schneider et al (2014) states, *"our first objective is to minimize the number of vehicles, i.e., a solution with fewer vehicles is always superior. The second objective is to minimize the total traveled distance"*. However, "*the objective of minimizing the traveled distance is defined in (1)*" does not mention the objective is to minimize the number of vehicles again. Since it is a hierarchical optimization, we set the coefficient of the number of vehicles as large as possible: 
   
      ```AMPL
      // Objective coefficient
      int M=1000; // implement that the first objective is to minimize the number of vehicles
      ```
   
      and the hierarchical optimization in the paper of Schneider et al (2014) is equivalent to the weighted sum optimization of the following two objective functions:
   
      ```AMPL
      // first objective is to minimize the number of vehicles and Objective function [1]
      
      minimize sum(i in StationsCustomers_0, j in StationsCustomers_N1 : i != j) (d[i][j]*x[i][j]) + sum(j in StationsCustomers_N1) x[0][j]*M;
      ```
   
   3. we just **set two copies** for each charging station in .dat files.
   
      ```AMPL
         	// Each dummy stations is visited at most once [3]
      	forall (i in Stations)
      		sum(j in StationsCustomers_N1 : i != j) x[i][j] <= 1;
      ```

Computational results for small-sized instances with 5 customers are shown as follows, where m denotes the vehicle number and f the traveled distance. t denotes the total run-time in seconds. **The left half is the results (CPLEX 12.2) in the paper of Schneider et al (2014), and the right half is the running results (CPLEX 20.1) of the updated CPLEX code**.

| Instances name | m    | f      | t    | m    | f             | t    |
| -------------- | ---- | ------ | ---- | ---- | ------------- | ---- |
| c101C5         | 2    | 257.75 | 81   | 2    | 257.747451864 | 0.40 |
| c103C5         | 1    | 176.05 | 5    | 1    | 176.054433149 | 0.18 |
| c206C5         | 1    | 242.55 | 518  | 1    | 242.555651715 | 3.07 |
| c208C5         | 1    | 158.48 | 15   | 1    | 158.480659584 | 0.46 |
| r104C5         | 2    | 136.69 | 1    | 2    | 136.689746806 | 0.50 |
| r105C5         | 2    | 156.08 | 3    | 2    | 156.082069464 | 0.32 |
| r202C5         | 1    | 128.78 | 1    | 1    | 128.777139072 | 1.28 |
| r203C5         | 1    | 179.06 | 5    | 1    | 179.055890818 | 3.31 |
| rc105C5        | 2    | 241.30 | 764  | 2    | 241.296391877 | 4.37 |
| rc108C5        | 1    | 253.92 | 311  | $\textcolor{red}{2}$ | 253.930685538 | 2.82 |
| rc204C5        | 1    | 176.39 | 54   | 1    | 176.394043113 | 43.72 |
| rc208C5        | 1    | 167.98 | 21   | 1    | 167.98346925 | 2.06 |

Insights on some areas that can be improved:

1.  Since we **set two copies** for each charging station, it is reasonable to add the constraint prohibiting trams from travelling between charging stations belonging to the same copy.
1.  Since we just **set two copies** for each charging station and tested on small-sized instances with 5 customers, it is reasonable to **set larger copies** for each charging station. However, the running time in CPLEX should also be taken into consideration.

(Updated on 08 April 2024, [Zubin Zheng](https://github.com/0SliverBullet))
