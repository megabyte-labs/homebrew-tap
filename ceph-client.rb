class CephClient < Formula
  desc "Ceph client tools and libraries"
  homepage "https://ceph.com"
  # url "http://download.ceph.com/tarballs/ceph-18.2.1.tar.gz"
  # sha256 "8075b03477f42ad23b1efd0cc1a0aa3fa037611fc059a91f5194e4b51c9d764a"
  url "https://github.com/ceph/ceph.git", :using => :git, :tag => "v18.2.1", :revision => "7fe91d5d5842e04be3b4f514d6dd990c54b29c76"
  version "18.2.1"
  license "MIT"

  # depends_on "homebrew/cask/macfuse"
  depends_on "boost@1.76"
  depends_on "openssl" => :build
  depends_on "cmake" => :build
  depends_on "cython"
  depends_on "ninja" => :build
  depends_on "leveldb" => :build
  depends_on "nss"
  depends_on "pkg-config" => :build
  depends_on "python@3.12"
  depends_on "python-setuptools"
  depends_on "python-wcwidth"
  depends_on "pyyaml"
  depends_on "sphinx-doc" => :build
  depends_on "yasm"

  def python3
    "python3.12"
  end

  resource "PrettyTable" do
    url "https://files.pythonhosted.org/packages/e1/c0/5e9c4d2a643a00a6f67578ef35485173de273a4567279e4f0c200c01386b/prettytable-3.9.0.tar.gz"
    sha256 "f4ed94803c23073a90620b201965e5dc0bccf1760b7a7eaf3158cab8aaffdf34"
  end

  patch :DATA

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["nss"].opt_lib}/pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["openssl"].opt_lib}/pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", "#{HOMEBREW_PREFIX}/lib/pkgconfig"
    python_version = Language::Python.major_minor_version python3
    ENV.prepend_create_path "PYTHONPATH", "#{Formula["cython"].opt_libexec}/lib/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", "#{Formula["python-setuptools"].opt_lib}/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", "#{Formula["python-wcwidth"].opt_lib}/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", "#{Formula["pyyaml"].opt_lib}/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", "#{Formula["sphinx-doc"].opt_libexec}/lib/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", "#{HOMEBREW_PREFIX}/lib/python#{python_version}/site-packages"
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python#{python_version}/site-packages"
    resources.each do |resource|
      resource.stage do
        system python3, *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    args = %W[
      -DDIAGNOSTICS_COLOR=always
      -DOPENSSL_ROOT_DIR=#{Formula["openssl"].opt_prefix}
      -DWITH_BABELTRACE=OFF
      -DWITH_BLUESTORE=OFF
      -DWITH_CCACHE=OFF
      -DWITH_CEPHFS=OFF
      -DWITH_KRBD=OFF
      -DWITH_LIBCEPHFS=ON
      -DWITH_LTTNG=OFF
      -DWITH_LZ4=OFF
      -DWITH_MANPAGE=ON
      -DWITH_MGR=OFF
      -DWITH_MGR_DASHBOARD_FRONTEND=OFF
      -DWITH_PYTHON3=#{python_version}
      -DWITH_RADOSGW=OFF
      -DWITH_RDMA=OFF
      -DWITH_SPDK=OFF
      -DWITH_SYSTEM_BOOST=ON
      -DWITH_SYSTEMD=OFF
      -DWITH_TESTS=OFF
      -DWITH_XFS=OFF
    ]
    targets = %w[
      rados
      rbd
      cephfs
      ceph-conf
      ceph-fuse
      manpages
      cython_rados
      cython_rbd
    ]
    mkdir "build" do
      system "cmake", "-G", "Ninja", "..", *args, *std_cmake_args
      system "ninja", *targets
      executables = %w[
        bin/rados
        bin/rbd
        bin/ceph-fuse
      ]
      executables.each do |file|
        MachO.open(file).linked_dylibs.each do |dylib|
          unless dylib.start_with?("/tmp/")
            next
          end
          MachO::Tools.change_install_name(file, dylib, "#{lib}/#{dylib.split('/')[-1]}")
        end
      end
      %w[
        ceph
        ceph-conf
        ceph-fuse
        rados
        rbd
      ].each do |file|
        bin.install "bin/#{file}"
      end
      %w[
        ceph-common.2
        ceph-common
        rados.2.0.0
        rados.2
        rados
        radosstriper.1.0.0
        radosstriper.1
        radosstriper
        rbd.1.17.0
        rbd.1
        rbd
        cephfs.2.0.0
        cephfs.2
        cephfs
      ].each do |name|
        lib.install "lib/lib#{name}.dylib"
      end
      %w[
        ceph-conf
        ceph-fuse
        ceph
        librados-config
        rados
        rbd
      ].each do |name|
        man8.install "doc/man/#{name}.8"
      end
      system "ninja", "src/pybind/install", "src/include/install"
    end

    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
    %w[
      ceph-conf
      ceph-fuse
      rados
      rbd
    ].each do |name|
      system "install_name_tool", "-add_rpath", "/opt/homebrew/lib", "#{libexec}/bin/#{name}"
    end
  end

  test do
    system "#{bin}/ceph", "--version"
    system "#{bin}/ceph-fuse", "--version"
    system "#{bin}/rbd", "--version"
    system "#{bin}/rados", "--version"
    system "python", "-c", "import rados"
    system "python", "-c", "import rbd"
  end
end

__END__
diff --git a/cmake/modules/Distutils.cmake b/cmake/modules/Distutils.cmake
index 9d66ae979a6..eabf22bf174 100644
--- a/cmake/modules/Distutils.cmake
+++ b/cmake/modules/Distutils.cmake
@@ -93,11 +93,9 @@ function(distutils_add_cython_module target name src)
     OUTPUT ${output_dir}/${name}${ext_suffix}
     COMMAND
     env
-    CC="${PY_CC}"
     CFLAGS="${PY_CFLAGS}"
     CPPFLAGS="${PY_CPPFLAGS}"
     CXX="${PY_CXX}"
-    LDSHARED="${PY_LDSHARED}"
     OPT=\"-DNDEBUG -g -fwrapv -O2 -w\"
     LDFLAGS=-L${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
     CYTHON_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
@@ -125,8 +123,6 @@ function(distutils_install_cython_module name)
     set(maybe_verbose --verbose)
   endif()
   install(CODE "
-    set(ENV{CC} \"${PY_CC}\")
-    set(ENV{LDSHARED} \"${PY_LDSHARED}\")
     set(ENV{CPPFLAGS} \"-iquote${CMAKE_SOURCE_DIR}/src/include
                         -D'void0=dead_function\(void\)' \
                         -D'__Pyx_check_single_interpreter\(ARG\)=ARG\#\#0' \
@@ -135,7 +131,7 @@ function(distutils_install_cython_module name)
     set(ENV{CYTHON_BUILD_DIR} \"${CMAKE_CURRENT_BINARY_DIR}\")
     set(ENV{CEPH_LIBDIR} \"${CMAKE_LIBRARY_OUTPUT_DIRECTORY}\")

-    set(options --prefix=${CMAKE_INSTALL_PREFIX})
+    set(options --prefix=${CMAKE_INSTALL_PREFIX} --install-lib=${CMAKE_INSTALL_PREFIX}/lib/python3.11/site-packages)
     if(DEFINED ENV{DESTDIR})
       if(EXISTS /etc/debian_version)
         list(APPEND options --install-layout=deb)
