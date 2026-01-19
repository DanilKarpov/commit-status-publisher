<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="util" uri="/WEB-INF/functions/util"%><c:if test="${showVcsTreeIcon}"
><script type="text/javascript">
  BS.VCS.registerTreePopup('${util:forJS(vcsTreeId, true, false)}', '${util:forJS(buildFormId, true, false)}', '${util:forJS(callback, true, false)}', '${util:forJS(fieldId, true, false)}', 'vcsTreeControl_${util:forJS(vcsTreeId, true, false)}', { dirsOnly: '${util:forJS(dirsOnly, true, false)}', vcsRootId: '${util:forJS(vcsRootId, true, false)}', rootDirName: '${util:forJS(rootDirName, true, false)}' } );
</script>
<c:set var="id">vcsTreeControl_<c:out value='${vcsTreeId}'/></c:set>
<bs:actionIcon name="folder" id="${id}" className="vcsTreeHandle" onclick="BS.VCS.showTree('${util:forJS(vcsTreeId, true, true)}')" title="Choose file or directory in VCS" />
</c:if>
