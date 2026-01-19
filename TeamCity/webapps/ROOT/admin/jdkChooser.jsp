<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<jsp:useBean id="availableJdks" type="jetbrains.buildServer.controllers.admin.AvailableJDKBean" scope="request"/>
<tr class="advancedSetting">
  <th><label for="jdk_home">JDK:</label></th>
  <td>
    <forms:select name="jdk_home" onchange="onJdkHomeChange()" enableFilter="true" className="mediumField">
      <forms:option value="default">&lt;Default&gt;</forms:option>
      <forms:option value="custom">&lt;Custom&gt;</forms:option>
      <c:forEach items="${availableJdks.jdks}" var="jdk">
        <forms:option value="${jdk.value}">${jdk.versionText}</forms:option>
      </c:forEach>
    </forms:select>
    <span class="smallNote" id="default_jdk">JAVA_HOME environment variable or the agent's own Java.</span>
    <span class="error" id="error_target.jdk.home"></span>
  </td>
</tr>
<tr id="custom_jdk_home" style="display: none;" class="advancedSetting">
  <th><label for="target.jdk.home">JDK home path: </label><bs:help file="Ant" anchor="JavaParameters"/></th>
  <td>
    <props:textProperty name="target.jdk.home" className="longField"/>
    <c:if test="${availableJdks.minJdkInfo != null}">
      <span class="smallNote"><c:out value='${availableJdks.minJdkInfo.versionText}'/> or higher is required.</span>
    </c:if>
  </td>
</tr>
<script type="text/javascript">
  window.onJdkHomeChange = function() {
    var selector = $('jdk_home');
    var selVal = selector.options[selector.selectedIndex].value;
    if (selVal == 'custom') {
      $('target.jdk.home').value = '';
    } else {
      if (selVal == 'default') {
        $('target.jdk.home').value = '';
      } else {
        $('target.jdk.home').value = selVal;
      }
    }

    window.updateJdkControlsVisibility();
  };

  window.updateJdkControlsVisibility = function() {
    var selector = $('jdk_home');
    var selVal = selector.options[selector.selectedIndex].value;
    if (selVal == 'custom') {
      BS.Util.show('custom_jdk_home');
      BS.Util.hide('default_jdk');
    } else {
      BS.Util.hide('custom_jdk_home');
      if (selVal == 'default') {
        BS.Util.show('default_jdk');
      } else {
        BS.Util.hide('default_jdk');
      }
    }

    BS.MultilineProperties.updateVisible();
  };

  window.populateSelector = function() {
    var selector = $('jdk_home');
    var homeField = $('target.jdk.home');
    var curHome = homeField.value;

    if (homeField.className.indexOf('valueChanged') != -1) {
      selector.parentNode.className += ' valueChanged';
    }

    if (curHome == '') {
      selector.selectedIndex = 0;
    } else {
      var found;
      for (var i = 0; i<selector.options.length; i++) {
        if (selector.options[i].value == curHome) {
          selector.selectedIndex = i;
          found = true;
        }
      }

      if (!found) {
        selector.selectedIndex = 1;
      }
    }

    BS.jQueryDropdown('#' + selector.id).ufd("changeOptions");
  };

  window.populateSelector();
  window.updateJdkControlsVisibility();
</script>
