# Temporary branch-specific notes

Purpose: modify CDS database and core code to support matching to centroids of all country-level polygos, where country is a multipolygon. 

Explanation: Changes to this branch will allow detection of centroids of disjunct polygons that are neither the largest subpolygon nor a second- or third-level administrative division (state or county). For example, the large Indonesian island of Sulawesi is divided into several political divisions, but is not itself a political division. Therefore, centroids of this island would not be detected by the current CDS algorithm, that detects only countries, states and counties.
