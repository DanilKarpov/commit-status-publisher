<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="tt" tagdir="/WEB-INF/tags/tests" %>

<jsp:useBean id="test" scope="request" type="jetbrains.buildServer.serverSide.STest"/>
<jsp:useBean id="testRuns" scope="request" type="java.util.List<jetbrains.buildServer.serverSide.STestRun>"/>
<c:set var="testDetailsId">tdi_${util:uniqueId()}</c:set>

<%--@elvariable id="contextProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="testRunsSerialized" type="java.lang.String"--%>

<div id="${testDetailsId}" class="testDetailsInline">
  <div class="simpleTabs clearfix"></div>
  <div class="hidden" id="fullBuildLinksMapping">
    <c:forEach items="${testRuns}" var="testRun">
      <div data-test-id="${testRun.testRunId}" data-build-id="${testRun.buildId}" class="buildLinkFull">
        <bs:buildLinkFull build="${testRun.build}" contextProject="${contextProject}"/>
      </div>
    </c:forEach>
  </div>
  <script>
    (function() {
      var projectId = '<%= request.getParameter("projectId") %>';
      var testRuns = ${testRunsSerialized};

      var tabs = new TabbedPane();

      var nonFailedBuilds = [];
      (function fillTabsForBuilds(tabs, testRuns) {
        testRuns.forEach(function fillTabsForFailedBuilds(testRun) {

          // Show menu item for 'copy stacktrace'
          var copyTR = $('copyInMenuLinkTR_' + testRun.buildId + '_' + testRun.testNameId);
          if (copyTR) {
            var testDataBlock = $j('#${testDetailsId}').find('.testBlockGeneral');
            testDataBlock.attr('data-copy-stacktrace-id', 'fullStacktrace_' + testRun.buildId + '_' + testRun.testNameId);
            copyTR.style.display = 'table-row';
          }

          if (testRun.status != 'Failed') {
            nonFailedBuilds.push(testRun);
            return;
          }

          var tabOptions = {
            caption: testRun.caption,
            onselect: function() {
              BS.Util.runWithElement('${testDetailsId}', function() {
                var myBlock = $('${testDetailsId}').down('.testBlockGeneral');
                var j_MyBlock = $j(myBlock);
                j_MyBlock.data('buildId', testRun.buildId);
                j_MyBlock.data('testId', testRun.testRunId);

                myBlock.show();

                BS.TestDetails.loadTestInformationForBuild(testRun.buildId, testRun.testRunId, projectId, testRun.testNameId, myBlock);
              }, 200);
              return false;
            }
          };

          // Update caption to mark configuration name in bold
          var caption = testRun.caption,
              idx = caption.lastIndexOf(" / "),
              patternLen = " / ".length;
          if (idx == -1) {
            idx = caption.lastIndexOf("...");
            patternLen = "...".length;
          }
          if (idx >= 0) {
            tabOptions.caption = caption.substr(0, idx + patternLen) + "<b>" + caption.substr(idx + patternLen) + "</b>";
          }

          // Append branch information to the tab:
          var branch = testRun.branch;
          if (branch) {
            if (branch.length > 16) {
              branch = branch.substr(0, 15) + "...";
            }
            branch = branch.escapeHTML();
            tabOptions.captionAddin =
              "<span class='branch hasBranch'>" +
                ReactUI.createAndRenderStatic(ReactUI.BuildBranch, {
                  name: testRun.branch,
                  main: testRun.defaultBranch,
                  noLink: true,
                  tailLength: 0,
                  className: 'testDetailsBranchName'
                }) +
              "</span>";
          }

          testRun.tabId = 'tab_' + testRun.testRunId + '_' + testRun.buildId;
          // Finally, add the tab:
          tabs.addTab(testRun.tabId, tabOptions);
        });

        if (nonFailedBuilds.length > 0) {
          // Create a tab for other, non-failed test runs:

          var buildHtmlFor = function(testRun) {
            var fullBuildLink = $j('#${testDetailsId} #fullBuildLinksMapping [data-test-id="' + testRun.testRunId + '"][data-build-id="' + testRun.buildId + '"]').html();
            var content = fullBuildLink + " &mdash; <span class='testStatus " + testRun.status.toLowerCase() + "'>" + testRun.status + "</span>";
            if (testRun.invocationCount > 1) {
              content += " (the test was run " + testRun.invocationCount + " times in the build)";
            }
            return "<div class='testRunLine'>" + content + "</div>";
          };
          var buildOtherCaption = function() {
            var partForStatus = function(status, suffix) {
              var count = nonFailedBuilds.reduce(function(prev, testRun) {
                return status == testRun.status ? prev + 1 : prev;
              }, 0);
              return count > 0 ? "" + count + suffix +", " : "";
            };

            var res = "Other: ";
            res += partForStatus("Successful", " successful");
            res += partForStatus("Ignored", " ignored");
            res += partForStatus("Muted", " muted");
            return res.substr(0, res.length - 2); // remove last ", "
          };

          tabs.addTab('otherBuilds', {
            caption: buildOtherCaption(),
            onselect: function() {

              var content = "";
              nonFailedBuilds.forEach(function(testRun) {
                content += buildHtmlFor(testRun);
              });

              var otherBlock = $j('#${testDetailsId} div.testBlock.otherBuilds');
              otherBlock.html(content);

              $j('#${testDetailsId} div.testBlock').hide();
              otherBlock.show();
            }
          });
        }
      })(tabs, testRuns);


      // Show tabs in container
      var tabsContainer = $("${testDetailsId}").down("div.simpleTabs");
      tabs.showIn(tabsContainer);

      if (tabs.getTabs().length > 1) {
        //content for first test run is shown by default
        tabs.getTabs()[0].setSelected(true);
        return;
      } else if (tabs.getTabs().length == 1 && nonFailedBuilds.length > 0) {
        tabs.setFirstActive();
      }
      tabsContainer.hide();
    })();
  </script>

  <div class="testBlock testBlockGeneral" data-copy-stacktrace-id="">
    <%@ include file="/change/testDetailsInfo.jsp" %>
  </div>

  <div class="testBlock otherBuilds" style="display: none;">
    <!-- to be filled with JS -->
  </div>
</div>
