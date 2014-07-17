require 'formula'

class Mcgrid < Formula
  homepage 'http://mcgrid.hepforge.org'
  url 'http://www.hepforge.org/archive/mcgrid/mcgrid-1.0.1.tar.gz'
  sha1 'acf81099444b2ec3c632de343a22e41ce9373ea6'

  depends_on 'rivet'
  depends_on 'applgrid'
  depends_on 'boost'
  depends_on 'pkg-config' => :build

  patch :DATA

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
    ]

    system "./configure", *args
    system "make", "install"

    prefix.install("examples")
    prefix.install("manual")
    # Scripts for subprocess extraction are currently missing in the downloadable tarball
    # bin.install Dir['scripts/*']
  end

  test do
    examples = prefix+'examples'
    system "make -C #{examples}"

    ENV['RIVET_ANALYSIS_PATH'] = examples
    ENV['RIVET_INFO_PATH'] = examples+'data'
    ENV['RIVET_REF_PATH'] = examples+'data'
    cp "#{examples}/subproc/MCgrid_CDF_2009_S8383952.config", "#{Formula['applgrid'].share}/applgrid"

    system "rivet #{examples}/hepmc/HepMC_CDFZ_NLO_Example.hepmc --ignore-beams -a MCgrid_CDF_2009_S8383952"
    rm "#{Formula['applgrid'].share}/applgrid/MCgrid_CDF_2009_S8383952.config"

    ohai "Successfully ran MCgrid analysis over Drell-Yan events"
  end

  def caveats; <<-EOS.undent
    A manual is installed in:
      $(brew --prefix mcgrid)/manual

    Examples are installed in:
      $(brew --prefix mcgrid)/examples

    Scripts for subprocess extraction are currently missing
    from the downloadable tarball.
    EOS
    # Scripts for subprocess extraction are installed in:
    #   $(brew --prefix mcgrid)/bin
    # They are called
    #   identify[Generator]Subprocs.py,
    # where `Generator` is "Amegic" or "Comix".
  end
end

__END__
diff --git a/examples/analyses/MCgrid_CDF_2009_S8383952.cc b/examples/analyses/MCgrid_CDF_2009_S8383952.cc
index 3f58287..0289c6a 100644
--- a/examples/analyses/MCgrid_CDF_2009_S8383952.cc
+++ b/examples/analyses/MCgrid_CDF_2009_S8383952.cc
@@ -34,9 +34,10 @@ namespace Rivet {
       /// Initialise and register projections here
       // this seems to have been corrected completely for all selection cuts,
       // i.e. eta cuts and pT cuts on leptons.
-      FinalState fs;
-      ZFinder zfinder(fs, -MAXRAPIDITY, MAXRAPIDITY, 0.0*GeV, PID::ELECTRON,
-                      66.0*GeV, 116.0*GeV, 0.2, true, true);
+      // Patch: MAXRAPIDITY was not definied anymore in Rivet 2.1.2, so we
+      // copied the line from the analysis in the 2.1.2 tarball.
+      ZFinder zfinder(FinalState(), -MAXDOUBLE, MAXDOUBLE, 0*GeV, PID::ELECTRON,
+                      66*GeV, 116*GeV, 0.2, ZFinder::CLUSTERNODECAY, ZFinder::TRACK);
       addProjection(zfinder, "ZFinder");
       
       /// Book histograms here
diff --git a/examples/testcode/applgrid-test.cpp b/examples/testcode/applgrid-test.cpp
index 3d07d98..fce1d9f 100644
--- a/examples/testcode/applgrid-test.cpp
+++ b/examples/testcode/applgrid-test.cpp
@@ -99,10 +99,14 @@ int main(int argc, char* argv[]) {
  exit(0);
 }
 
+// Patch: There are no FORTRAN wrappers as of LHAPDF v.6
+#ifndef LHAPDF_MAJOR_VERSION
+// We should be on an old LHAPDF version (below 6),
+// which still relies on FORTRAN
 
 #include "LHAPDF/FortranWrappers.h"
 #ifdef FC_DUMMY_MAIN
 int FC_DUMMY_MAIN() { return 1; }
 #endif
 
-
+#endif