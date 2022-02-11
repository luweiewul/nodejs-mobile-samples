#!/bin/sh

abi_name="arm64-v8a"

case $abi_name in

  armeabi-v7a)
    temp_arch="arm"
    ;;

  arm64-v8a)
    temp_arch="arm64"
    ;;

  *)
    temp_arch="${abi_name}"
    ;;
esac
temp_cc_ver="4.9"
case $temp_arch in

  arm)
    temp_dest_cpu="${temp_arch}"
    temp_v8_arch="${temp_arch}"
    temp_suffix="${temp_arch}-linux-androideabi"
    temp_toolchain_name="${temp_suffix}"
    ;;

  x86)
    temp_dest_cpu='ia32'
    temp_v8_arch='ia32'
    temp_suffix='i686-linux-android'
    temp_toolchain_name="${temp_arch}"
    ;;

  x86_64)
    temp_dest_cpu='x64'
    temp_v8_arch='x64'
    temp_suffix="${temp_arch}-linux-android"
    temp_toolchain_name="${temp_arch}"
    ;;

  arm64)
	temp_dest_cpu="${temp_arch}"
	temp_v8_arch="${temp_arch}"
	temp_suffix='aarch64-linux-android'
	temp_toolchain_name='aarch64'
    ;;

  *)
    echo "Unsupported architecture for nodejs-mobile native modules: ${temp_arch}"
    exit 1
    ;;
esac

export npm_config_node_engine="v8"
export npm_config_nodedir="$PWD/app/libnode/"
export npm_config_node_gyp="$PWD/node_modules/nodejs-mobile-gyp/bin/node-gyp.js"
export npm_config_arch=$temp_arch
export npm_config_platform="android"
export npm_config_format="make-android"

#应该生成lib/binding/{node_abi}-{platform}-{arch}/*.node，比如arm64-v8a-android-arm64/node_sqlite3.node
#npm -> node-pre-gyp/lib/node-pre-gyp.js -> node-pre-gyp/lib/configure.js -> node-pre-gyp/lib/util/handle_gyp_opts.js -> node-pre-gyp/lib/util/versioning.js
#调用nodejs-mobile-gyp/bin/node-gyp.js的参数--module, --module_path是在node-pre-gyp/lib/util/versioning.js module.exports.evaluate里根据要编译module的package.json以及node-pre-gyp.js里处理的命令行和npm_config_环境变量参数options组合计算出来的
#node_abi: get_runtime_abi(runtime,options.target),
#platform: options.target_platform || process.platform,
#arch: options.target_arch || process.arch,
#opts.module_path = eval_template(package_json.binary.module_path,opts);
#node_abi应该传入target指定nodejs-mobile库的版本 https://github.com/JaneaSystems/nodejs-mobile/releases “Node.js for Mobile Apps core library v0.3.3” built with node 12.19.0
#export npm_config_target="12.19.0"
#但是"sqlite3": "^4.0.0"用的"node-pre-gyp": "^0.11.0"只能识别到到10.8.0（node-pre-gyp/lib/util/abi_crosswalk.json）
#所以只能不设置target，而是用同版本的node来运行
echo "!! sudo n 12.19.0 !!"
export npm_config_target_arch=$temp_arch
export npm_config_target_platform="android"

#Adds the original project .bin to the path. It's a workaround
#to correctly build some modules that depend on symlinked modules,
#like node-pre-gyp.
original_project_bin="$PWD/app/src/main/assets/nodejs-project/node_modules/.bin"
export PATH=$PATH:$original_project_bin

standalone_toolchain="$PWD/standalone-toolchains/${temp_toolchain_name}"
#copy nodejs-mobile-samples/cordova/UseNativeModules/platforms/android/build/standalone-toolchains to nodejs-mobile-samples/android/native-gradle-node-folder/standalone-toolchains
if [[ ! -d /$PWD/standalone-toolchains ]]; then
	mkdir standalone-toolchains
fi
if [[ ! -d ${standalone_toolchain} ]]; then
	if [[ -z "${ANDROID_NDK_HOME}" ]]; then
		echo "Environment variable ANDROID_NDK_HOME must be defined!"
	else
		${ANDROID_NDK_HOME}/build/tools/make-standalone-toolchain.sh --toolchain=${temp_toolchain_name}-${temp_cc_ver} --arch=${temp_arch} --install-dir=${standalone_toolchain} --stl=libc++ --force --platform=android-22
	fi
fi

npm_toolchain_ar="${standalone_toolchain}/bin/${temp_suffix}-ar"
npm_toolchain_cc="${standalone_toolchain}/bin/${temp_suffix}-clang"
npm_toolchain_cxx="${standalone_toolchain}/bin/${temp_suffix}-clang++"
npm_toolchain_link="${standalone_toolchain}/bin/${temp_suffix}-clang++"

npm_gyp_defines="target_arch=${temp_arch} v8_target_arch=${temp_v8_arch} android_target_arch=${temp_arch} host_os=mac OS=android"

export TOOLCHAIN="${standalone_toolchain}"
export AR="${npm_toolchain_ar}"
export CC="${npm_toolchain_cc}"
export CXX="${npm_toolchain_cxx}"
export LINK="${npm_toolchain_link}"
export GYP_DEFINES="${npm_gyp_defines}"

cd app/src/main/assets/nodejs-project

npm --verbose rebuild --build-from-source

