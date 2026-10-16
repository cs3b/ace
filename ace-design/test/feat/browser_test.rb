# frozen_string_literal: true
require_relative "../test_helper"
require "net/http"
require "open3"
require "timeout"
class BrowserTest < DesignTest
  RUNTIME = File.expand_path("../../../.ace-local/design/runtime", __dir__)
  def with_server(root)
    Ace::Design::Molecules::Session.new(root).write_gallery
    Open3.popen3("node", File.join(Ace::Design.gem_root, "browser/preview.mjs"), root, "0") do |stdin, stdout, stderr, waiter|
      stdin.close
      line = Timeout.timeout(10) { stdout.gets }
      assert_match(/Preview: http/, line.to_s)
      uri = URI(line.split.last)
      yield uri
    ensure
      Process.kill("TERM", waiter.pid) if waiter.alive?
      Timeout.timeout(5) { waiter.value }
    end
  end
  def get(uri, path, host: nil)
    http = Net::HTTP.new(uri.host, uri.port, nil)
    http.open_timeout = http.read_timeout = 5
    request = Net::HTTP::Get.new(path)
    request["Host"] = host if host
    http.request(request)
  end
  def test_preview_exposes_only_session_assets_and_keeps_shared_data
    with_session do |root|
      File.write(File.join(root, "secret.json"), "private")
      File.binwrite(File.join(root, "variants/a/preview.gif"), "GIF89a")
      Dir.mktmpdir do |outside|
        File.write(File.join(outside, "outside.json"), "outside")
        with_server(root) do |uri|
          File.symlink(File.join(root, "secret.json"), File.join(root, "variants/a/leak.json"))
          File.symlink(File.join(outside, "outside.json"), File.join(root, "variants/a/outside.json"))
          assert_equal "200", get(uri, "/").code
          assert_equal File.read(File.join(root, "fixtures.json")), get(uri, "/fixtures.json").body
          assert_equal "200", get(uri, "/variants/a/index.html").code
          assert_equal "image/gif", get(uri, "/variants/a/preview.gif")["content-type"]
          assert_equal "404", get(uri, "/variants/a/").code
          assert_equal "404", get(uri, "/secret.json").code
          assert_equal "403", get(uri, "/variants/a/%2e%2e/%2e%2e/secret.json").code
          assert_equal "403", get(uri, "/variants/a/outside.json").code
          assert_equal "403", get(uri, "/variants/a/leak.json").code
          assert_equal "403", get(uri, "/", host: "evil.example").code
        end
      end
    end
  end
  def test_preview_routes_declared_custom_variant_only
    with_session do |root|
      metadata = JSON.parse(File.read(File.join(root, "session.json")))
      metadata["variants"] = ["detail"]
      File.write(File.join(root, "session.json"), JSON.generate(metadata))
      File.rename(File.join(root, "variants/a"), File.join(root, "variants/detail"))
      with_server(root) do |uri|
        assert_equal "200", get(uri, "/variants/detail/index.html").code
        assert_equal "404", get(uri, "/variants/b/index.html").code
        assert_equal "404", get(uri, "/run.json").code
      end
    end
  end
  def test_inspection_engine_gate_matches_pinned_dependency_minimum
    dependency_script = File.join(Ace::Design.gem_root, "browser/dependencies.mjs")
    %w[21.9.0 22.0.0 22.11.9 22.12.0 23.0.0 24.0.0].each do |version|
      script = <<~JS
        Object.defineProperty(process.versions,'node',{value:process.argv[1]});
        const {dependencies}=await import(process.argv[2]);
        try { dependencies('/missing-design-runtime'); } catch(e) { console.log(e.message); }
      JS
      output, error, status = Open3.capture3("node", "--input-type=module", "-e", script, version, dependency_script)
      assert status.success?, error
      if %w[21.9.0 22.0.0 22.11.9].include?(version)
        assert_match(/Node 22.12\+ is required/, output)
      else
        assert_match(/Missing playwright/, output)
      end
    end
  end
  def test_doctor_reports_missing_and_mismatched_dependencies
    Dir.mktmpdir do |runtime_dir|
      runtime = Ace::Design::Molecules::Runtime.new({"node" => "node", "runtime_dir" => runtime_dir})
      result = runtime.doctor
      refute result["ready"]
      assert_match(/Missing playwright/, result["error"])
      FileUtils.mkdir_p(File.join(runtime_dir, "node_modules/playwright"))
      File.write(File.join(runtime_dir, "node_modules/playwright/package.json"), '{"version":"0.0.0"}')
      result = runtime.doctor
      refute result["ready"]
      assert_match(/Expected playwright/, result["error"])
    end
  end

  def test_browser_cleanup_failure_preserves_an_incomplete_report
    Dir.mktmpdir do |root|
      runtime_dir = File.join(root, "runtime")
      versions = JSON.parse(File.read(File.join(Ace::Design.gem_root, "browser/package.json"))).fetch("dependencies")
      versions.each do |name, version|
        dir = File.join(runtime_dir, "node_modules", name)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "package.json"), JSON.generate({"version" => version, "main" => "index.js"}))
        code = name == "playwright" ? "exports.chromium={executablePath:()=>process.execPath,launch:async()=>({newContext:async()=>{throw Error('fixture setup failed')},close:async()=>{throw Error('fixture cleanup failed')}})};" : "module.exports=class {};"
        File.write(File.join(dir, "index.js"), code)
      end
      runtime = Ace::Design::Molecules::Runtime.new({"node" => "node", "runtime_dir" => runtime_dir})
      runner = Ace::Design::Organisms::Inspector.new(config: {"timeout" => 1, "run_root" => root}, runtime: runtime)
      result = runner.run(url: "http://localhost", surface: "site")
      assert_equal "incomplete", result["status"]
      assert_equal 2, result["errors"].length
      assert_match(/cleanup failed/, result["errors"].last["message"])
      assert File.file?(result["report_path"].sub(".json", ".md"))
    end
  end
  def test_real_browser_reports_clean_findings_and_incomplete_truthfully
    assert File.directory?(File.join(RUNTIME, "node_modules")), "Install browser runtime as documented before feature tests"
    original = ENV["PLAYWRIGHT_BROWSERS_PATH"]
    ENV["PLAYWRIGHT_BROWSERS_PATH"] = File.join(RUNTIME, "browsers")
    runtime = Ace::Design::Molecules::Runtime.new({"node" => "node", "runtime_dir" => RUNTIME})
    assert runtime.doctor["ready"], "Install Chromium in #{RUNTIME}/browsers before feature tests"
    with_session do |root|
      good = '<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width"><title>Test</title></head><body><main><h1>Shared title</h1><button type="button">Continue</button></main></body></html>'
      File.write(File.join(root, "variants/a/index.html"), good)
      File.write(File.join(root, "variants/b/index.html"), good.sub('</main>', '<img src="/missing.png"><div style="width:2400px">Overflow</div></main>'))
      with_server(root) do |uri|
        gallery_check = <<~JS
          const {chromium}=require(process.argv[1]);
          (async()=>{const browser=await chromium.launch({headless:true});
          try {const page=await browser.newPage();await page.goto(process.argv[2]);
          const frames=page.frames().filter(f=>f.parentFrame());
          for(const frame of frames) await frame.waitForFunction(()=>innerWidth===1200);
          const isolated=await frames[0].evaluate(()=>{try {parent.document.body;return false;}catch{return true;}});
          const fixtures=await frames[0].evaluate(async()=>{const r=await fetch('../../fixtures.json');return r.ok;});
          await page.getByLabel('Preview width').selectOption('390');
          for(const frame of frames) await frame.waitForFunction(()=>innerWidth===390);
          const widths=await Promise.all(frames.map(f=>f.evaluate(()=>innerWidth)));
          const fits=await page.locator('iframe').evaluateAll(frames=>frames.every(f=>Math.abs(f.getBoundingClientRect().width-f.parentElement.clientWidth)<1));
          console.log(JSON.stringify({widths,fits,isolated,fixtures}));
          } finally {await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
        JS
        result = runtime.capture("node", "-e", gallery_check, File.join(RUNTIME,"node_modules/playwright"), uri.to_s, timeout: 15)
        assert_equal 0, result["exit_code"], result["stderr"]
        assert_equal({"widths" => [390,390,390], "fits" => true, "isolated" => true, "fixtures" => true}, JSON.parse(result["stdout"]))
        Dir.mktmpdir do |out|
          inspector = Ace::Design::Organisms::Inspector.new(config: {"timeout" => 20, "run_root" => out}, runtime: runtime)
          clean = inspector.run(url: "#{uri}variants/a/index.html", surface: "site", out: File.join(out,"good"))
          assert_equal "pass", clean["status"], clean.inspect
          assert_equal [390,768,1440], clean["viewports"].map { |v| v["width"] }
          clean["viewports"].each { |v| assert File.size(File.join(out,"good",v["screenshot"])) > 100 }
          broken = inspector.run(url: "#{uri}variants/b/index.html", surface: "app", out: File.join(out,"broken"))
          assert_equal "findings", broken["status"]
          assert_includes broken["findings"].map { |f| f["rule"] }, "horizontal-overflow"
          assert_includes broken["findings"].map { |f| f["rule"] }, "broken-image"
          assert_includes broken["findings"].map { |f| f["rule"] }, "accessibility"
          missing = inspector.run(url: "#{uri}missing", surface: "app", out: File.join(out,"missing"))
          assert_equal "incomplete", missing["status"]
          assert_equal 3, missing["errors"].length
        end
      end
    end
  ensure
    original ? ENV["PLAYWRIGHT_BROWSERS_PATH"] = original : ENV.delete("PLAYWRIGHT_BROWSERS_PATH")
  end
end
