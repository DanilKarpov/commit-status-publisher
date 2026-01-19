<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>

<%@ page import="jetbrains.buildServer.serverSide.impl.agent.JdkPackageProvider.OS" %>
<%@ page import="jetbrains.buildServer.serverSide.impl.agent.JdkPackageProvider.Arch" %>
<%@ page import="jetbrains.buildServer.serverSide.JdkPackageManager" %>

<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="escapedPageUrl" value="<%=WebUtil.encode(pageUrl)%>"/>

<jsp:useBean id="jdkList" scope="request" type="java.util.List<jetbrains.buildServer.serverSide.impl.agent.JdkPackageInfo>"/>
<jsp:useBean id="restPath" scope="request" type="java.lang.String"/>

<bs:linkScript>
  /js/bs/jdkDialog.js
</bs:linkScript>

<style>
  .popupBody div {
    padding: 0.5em;
  }
</style>

<div id="serverConfigIncludedJdk">
  <div class="serverConfigPage">
    <bs:smallNote>
      On this page you can add a JDK package that TeamCity will use for building system-specific agent distributions. <br/>
      After new JDK package is added corresponding agent distribution can be found on <a id="agentsLink" href="<c:url value='/installFullAgent.html'/>">Agent Distributions</a> page.
      TeamCity supports <b>.tar.gz</b> and <b>.zip</b> JDK packages
    </bs:smallNote>
    <bs:refreshable pageUrl="${pageUrl}" containerId="includedJdks">
      <ui:debug hotkey="x" />
      <c:if test="${JdkPackageManager.areJdksBeingBuilt(jdkList)}">
        <script type="text/javascript" >
          BS.AddJdkDialog.scheduleRefresh();
        </script>
      </c:if>

      <table class="runnerFormTable">

        <tr id="jdkListForAgentDistributionButton">
          <td colspan="2">
            <forms:addButton onclick="BS.AddJdkDialog.showCentered(); return false;">Add JDK</forms:addButton>
          </td>
        </tr>

        <tr id="jdkListForAgentDistributionTable">
          <td colspan="2">
            <table id="addedJdkList" class="settings installed-versions">
              <tr>
                <th style="width: 5%">OS</th>
                <th style="width: 5%">Architecture</th>
                <th style="width: 5%">Version</th>
                <th>URL</th>
              </tr>
              <c:forEach var="jdk" items="${jdkList}">
                <tr>
                  <td>${jdk.os}</td>
                  <td>${jdk.arch}</td>
                  <td>${jdk.version == null ? jdk.statusDescription : jdk.version}</td>
                  <td>
                    <div>
                      <div style="float:left; width: 90%">
                        <a id="${jdk.os}${jdk.arch}-url" href="${jdk.url}">${jdk.url}</a>
                        <c:if test="${jdk.error != null}">
                          <div class="error" style="margin-left: 0">${jdk.error}</div>
                        </c:if>
                      </div>
                      <a style="float:right" class="removeJdkButton" href="#" onclick="BS.AddJdkDialog.removeJdk('${jdk.os}', '${jdk.arch}', '${restPath}'); return false;">
                        <bs:svgIcon name="trash" className="actionIcon"/>
                      </a>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </table>
          </td>
        </tr>
      </table>

    </bs:refreshable>
  </div>
</div>

<bs:modalDialog dialogClass="AddJdkDialog"
                formId="AddJdkDialogForm"
                title="Add JDK"
                saveCommand="BS.AddJdkDialog.submit('${restPath}')"
                closeCommand="BS.AddJdkDialog.close()"
                action="">
  <div class="popupBody">
  <table class="runnerFormTable">
    <tr>
      <th class="noBorder"><label for="jdkOS">OS:</label></th>
      <td>
        <forms:select name="jdkOS" className="smallField">
          <c:forEach items="<%=OS.values()%>" var="os">
            <forms:option value="${os.name}">${os.name}</forms:option>
          </c:forEach>
        </forms:select>
      </td>
    </tr>
    <tr>
      <th class="noBorder"><label for="jdkArch">Architecture:</label></th>
      <td>
        <forms:select name="jdkArch" className="smallField">
          <c:forEach items="<%=Arch.values()%>" var="arch">
            <forms:option value="${arch.name}">${arch.name}</forms:option>
          </c:forEach>
        </forms:select>
      </td>
    </tr>
    <tr>
      <th class="noBorder"><label for="jdkUrl">URL: <l:star/></label></th>
      <td>
        <forms:textField name="jdkUrl" id="jdkUrl" expandable="true" className="longField"/>
        <span class="error" id="error_jdkUrl"></span>
        <span class="smallNote">E.g. https://example.com/path/to/jdk.tar.gz</span>
      </td>
    </tr>
  </table>

  <div class="popupSaveButtonsBlock">
    <forms:submit id="addJdkApplyButton" label="Add"/>
    <forms:cancel onclick="BS.AddJdkDialog.close();"/>
    <forms:saving id="addJdkProgress"/>
  </div>
</bs:modalDialog>

<script type="text/javascript">
  $j(function() {
    <c:if test="${not afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
    $j('.removeJdkButton').addClass("hidden");
    $j('#jdkListForAgentDistributionButton').addClass("hidden");
    </c:if>
  });

</script>
